/// <reference path="../pb_data/types.d.ts" />

/**
 * Оформление продажи: проверка остатка, списание, позиции чека, баллы лояльности.
 * POST /api/shop/sales
 * body: { customerId, items: [{ productId, quantity }] }
 */
routerAdd(
  "POST",
  "/api/shop/sales",
  (e) => {
    const auth = e.auth;
    if (!auth) {
      throw new UnauthorizedError("Требуется вход.");
    }
    const role = auth.get("role");
    if (role !== "librarian" && role !== "admin") {
      throw new ForbiddenError("Оформлять продажи может только менеджер.");
    }

    const body = e.requestInfo().body || {};
    const customerId = body.customerId;
    const items = body.items;
    if (!customerId || !Array.isArray(items) || items.length === 0) {
      throw new BadRequestError("Укажите клиента и хотя бы одну позицию.");
    }

    const customer = $app.findRecordById("customers", customerId);
    if (!customer || customer.get("deleted") === true) {
      throw new NotFoundError("Клиент не найден.");
    }

    let total = 0;
    const prepared = [];
    for (const line of items) {
      const productId = line.productId;
      const quantity = Number(line.quantity || 0);
      if (!productId || quantity < 1) {
        throw new BadRequestError("Некорректная позиция продажи.");
      }
      const product = $app.findRecordById("products", productId);
      if (!product || product.get("deleted") === true) {
        throw new NotFoundError("Товар не найден.");
      }
      const stock = Number(product.get("stock") || 0);
      if (quantity > stock) {
        const name = product.get("name");
        return e.json(409, {
          message: `Недостаточно «${name}»: на складе ${stock}`,
          productId: productId,
          stock: stock,
        });
      }
      const unitPrice = Number(product.get("price") || 0);
      total += unitPrice * quantity;
      prepared.push({ product, quantity, unitPrice });
    }

    const salesCol = $app.findCollectionByNameOrId("sales");
    const sale = new Record(salesCol);
    sale.set("customer", customerId);
    sale.set("total", total);
    const pointsEarned = Math.floor(total / 100);
    sale.set("pointsEarned", pointsEarned);
    sale.set("deleted", false);
    $app.save(sale);

    const itemsCol = $app.findCollectionByNameOrId("sale_items");
    for (const row of prepared) {
      const item = new Record(itemsCol);
      item.set("sale", sale.id);
      item.set("product", row.product.id);
      item.set("quantity", row.quantity);
      item.set("unitPrice", row.unitPrice);
      item.set("deleted", false);
      $app.save(item);

      row.product.set("stock", Number(row.product.get("stock")) - row.quantity);
      $app.save(row.product);
    }

    // Начисление баллов на карту лояльности (1:1 с клиентом).
    try {
      const cards = $app.findRecordsByFilter(
        "loyalty_cards",
        `customer = "${customerId}" && deleted != true`,
        "",
        1,
        0,
      );
      if (cards && cards.length > 0) {
        const card = cards[0];
        const points = Number(card.get("points") || 0) + pointsEarned;
        card.set("points", points);
        if (points >= 5000) card.set("level", "Платина");
        else if (points >= 2000) card.set("level", "Золото");
        else if (points >= 500) card.set("level", "Серебро");
        else card.set("level", "Стандарт");
        $app.save(card);
      }
    } catch (_) {}

    const expanded = $app.findRecordById("sales", sale.id);
    return e.json(201, {
      id: expanded.id,
      customerId: customerId,
      total: total,
      pointsEarned: pointsEarned,
      customer: {
        id: customer.id,
        fullName: customer.get("fullName"),
      },
    });
  },
  $apis.requireAuth(),
);

/**
 * При создании клиента автоматически создаём карту и учётку покупателя,
 * чтобы число клиентов = числу пользователей.
 */
onRecordAfterCreateSuccess((e) => {
  const record = e.record;
  if (!record || record.collection().name !== "customers") return;

  const customerId = record.id;
  const email = String(record.get("email") || "").toLowerCase();
  const fullName = String(record.get("fullName") || "Покупатель");
  if (!email) return;

  // Карта лояльности 1:1
  try {
    const existingCards = $app.findRecordsByFilter(
      "loyalty_cards",
      `customer = "${customerId}"`,
      "",
      1,
      0,
    );
    if (!existingCards || existingCards.length === 0) {
      const cardsCol = $app.findCollectionByNameOrId("loyalty_cards");
      const card = new Record(cardsCol);
      card.set("number", `LC-${customerId.slice(0, 8).toUpperCase()}`);
      card.set("issuedAt", new Date().toISOString());
      card.set("points", 0);
      card.set("level", "Стандарт");
      card.set("customer", customerId);
      card.set("deleted", false);
      $app.save(card);
    }
  } catch (_) {}

  // Учётка reader, если ещё нет пользователя с этим email / customerId
  try {
    const byCustomer = $app.findRecordsByFilter(
      "users",
      `customerId = "${customerId}"`,
      "",
      1,
      0,
    );
    if (byCustomer && byCustomer.length > 0) return;

    let username = email.split("@")[0] || `buyer_${customerId.slice(0, 6)}`;
    username = username.replace(/[^a-zA-Z0-9_]/g, "_").slice(0, 40);
    if (username.length < 3) username = `buyer_${customerId.slice(0, 6)}`;

    const usersCol = $app.findCollectionByNameOrId("users");
    const user = new Record(usersCol);
    user.set("username", username);
    user.set("email", email);
    user.set("emailVisibility", true);
    user.set("password", "reader123");
    user.set("passwordConfirm", "reader123");
    user.set("fullName", fullName);
    user.set("role", "reader");
    user.set("customerId", customerId);
    user.set("verified", true);
    $app.save(user);
  } catch (err) {
    console.log("ensure user for customer failed", err);
  }
}, "customers");

/** Вход по username или email. */
routerAdd("POST", "/api/shop/login", (e) => {
  const body = e.requestInfo().body || {};
  const identity = String(body.identity || body.username || "").trim();
  const password = String(body.password || "");
  if (!identity || !password) {
    throw new BadRequestError("Укажите логин и пароль.");
  }

  let record = null;
  try {
    if (identity.includes("@")) {
      record = $app.findAuthRecordByEmail("users", identity);
    } else {
      record = $app.findFirstRecordByFilter(
        "users",
        "username = {:u}",
        { u: identity },
      );
    }
  } catch (_) {
    record = null;
  }

  if (!record || !record.validatePassword(password)) {
    throw new BadRequestError("Неверный логин или пароль.");
  }

  return $apis.recordAuthResponse(e, record);
});

/** Регистрация покупателя: клиент (+ хук создаёт карту и учётку), затем пароль/логин. */
routerAdd("POST", "/api/shop/register", (e) => {
  const body = e.requestInfo().body || {};
  const username = String(body.username || "").trim();
  const password = String(body.password || "");
  const fullName = String(body.fullName || "").trim();
  const email = String(body.email || "").trim().toLowerCase();

  if (username.length < 3 || password.length < 6 || fullName.length < 2 || !email) {
    return e.json(422, {
      message: "Проверьте поля формы",
      errors: {
        username: username.length < 3 ? "Минимум 3 символа" : "",
        password: password.length < 6 ? "Минимум 6 символов" : "",
        fullName: fullName.length < 2 ? "Укажите имя" : "",
        email: !email ? "Укажите email" : "",
      },
    });
  }

  const customersCol = $app.findCollectionByNameOrId("customers");
  const customer = new Record(customersCol);
  customer.set("fullName", fullName);
  customer.set("email", email);
  customer.set("phone", body.phone || "+7 (000) 000-00-00");
  customer.set("deleted", false);
  $app.save(customer);
  // onRecordAfterCreateSuccess уже создал карту и пользователя-читателя.

  const users = $app.findRecordsByFilter(
    "users",
    `customerId = "${customer.id}"`,
    "",
    1,
    0,
  );
  if (!users || users.length === 0) {
    throw new BadRequestError("Не удалось создать учётку покупателя.");
  }
  const user = users[0];
  user.set("username", username);
  user.set("password", password);
  user.set("passwordConfirm", password);
  user.set("fullName", fullName);
  user.set("email", email);
  user.set("role", "reader");
  user.set("verified", true);
  $app.save(user);

  return e.json(201, {
    id: user.id,
    username: username,
    fullName: fullName,
    email: email,
    role: "reader",
    customerId: customer.id,
  });
});
