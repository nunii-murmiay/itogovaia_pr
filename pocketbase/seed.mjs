/**
 * Заполнение PocketBase демо-данными зоомагазина.
 * Запуск: node seed.mjs
 * Перед этим: pocketbase.exe serve и созданный суперадмин.
 */
const BASE = process.env.PB_URL || "http://127.0.0.1:8090";
const ADMIN_EMAIL = process.env.PB_ADMIN_EMAIL || "admin@zoomag.local";
const ADMIN_PASS = process.env.PB_ADMIN_PASS || "admin123456";

async function req(path, { method = "GET", token, body } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: token } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status}: ${JSON.stringify(data)}`);
  }
  return data;
}

async function create(token, collection, record) {
  return req(`/api/collections/${collection}/records`, {
    method: "POST",
    token,
    body: record,
  });
}

async function main() {
  // Auth as superuser (PB 0.23+ uses /api/collections/_superusers/auth-with-password)
  let token;
  try {
    const auth = await req("/api/collections/_superusers/auth-with-password", {
      method: "POST",
      body: { identity: ADMIN_EMAIL, password: ADMIN_PASS },
    });
    token = auth.token;
  } catch {
    const auth = await req("/api/admins/auth-with-password", {
      method: "POST",
      body: { identity: ADMIN_EMAIL, password: ADMIN_PASS },
    });
    token = auth.token;
  }

  console.log("Admin OK");

  const suppliersData = [
    ["Royal Canin Distribution", "Франция", "Жан-Люк Дюпон", "+7 (495) 123-45-67", "contact@royalcanin.fr", 4.9],
    ["Purina Russia", "США", "Марк Джонсон", "+7 (495) 234-56-78", "info@purina.com", 4.8],
    ["Tetra Russia", "Германия", "Ганс Шмидт", "+7 (495) 345-67-89", "support@tetra.net", 4.7],
    ["Ferplast Import", "Италия", "Марко Росси", "+7 (495) 456-78-90", "sales@ferplast.it", 4.6],
    ["Beaphar Nord", "Нидерланды", "Виллем ван Дейк", "+7 (495) 567-89-01", "nl@beaphar.com", 4.7],
  ];
  const suppliers = [];
  for (const [name, country, contactPerson, phone, email, rating] of suppliersData) {
    suppliers.push(
      await create(token, "suppliers", {
        name, country, contactPerson, phone, email, rating, deleted: false,
      }),
    );
  }

  const categoriesData = [
    ["Корма", "Сухие и влажные корма", "restaurant"],
    ["Игрушки", "Игрушки для животных", "toys"],
    ["Аксессуары", "Амуниция и миски", "pets"],
    ["Гигиена", "Шампуни и наполнители", "soap"],
    ["Аквариум", "Всё для рыбок", "water"],
  ];
  const categories = [];
  for (const [name, description, iconName] of categoriesData) {
    categories.push(
      await create(token, "categories", {
        name, description, iconName, deleted: false,
      }),
    );
  }

  const brandsData = [
    ["Royal Canin", "Франция", "Ветеринарные корма", [0]],
    ["Purina", "США", "Повседневные корма", [1]],
    ["Tetra", "Германия", "Для аквариума", [2]],
    ["Ferplast", "Италия", "Клетки и переноски", [3]],
    ["Beaphar", "Нидерланды", "Гигиена и витамины", [4]],
  ];
  const brands = [];
  for (const [name, country, description, sIdx] of brandsData) {
    brands.push(
      await create(token, "brands", {
        name,
        country,
        description,
        suppliers: sIdx.map((i) => suppliers[i].id),
        deleted: false,
      }),
    );
  }

  const productsData = [
    ["RC Adult Dog", "RC-DOG-001", 0, [0], [0], 4290, 40, 4.8],
    ["Purina One Cat", "PU-CAT-010", 1, [1], [1], 1890, 55, 4.5],
    ["Tetra Min Flakes", "TE-AQ-003", 2, [4], [2], 650, 80, 4.6],
    ["Ferplast Cage", "FE-ACC-007", 3, [2], [3], 5200, 12, 4.3],
    ["Beaphar Shampoo", "BE-HYG-002", 4, [3], [4], 790, 30, 4.4],
    ["RC Kitten", "RC-CAT-002", 0, [0], [0], 3590, 25, 4.7],
    ["Purina Dental", "PU-DOG-020", 1, [1], [1], 990, 40, 4.2],
    ["Tetra EasyCrystal", "TE-AQ-011", 2, [4], [2], 1450, 18, 4.5],
  ];
  const products = [];
  for (const [name, sku, s, cIdx, bIdx, price, stock, rating] of productsData) {
    products.push(
      await create(token, "products", {
        name,
        sku,
        supplier: suppliers[s].id,
        categories: cIdx.map((i) => categories[i].id),
        brands: bIdx.map((i) => brands[i].id),
        price,
        stock,
        rating,
        deleted: false,
      }),
    );
  }

  const customersData = [
    ["Кузнецова М. И.", "kuznetsova@mail.ru", "+7 (900) 111-11-11"],
    ["Попов Д. А.", "popov@mail.ru", "+7 (900) 222-22-22"],
    ["Васильева Е. В.", "vasileva@mail.ru", "+7 (900) 333-33-33"],
    ["Администратор", "admin@zoomag.local", "+7 (900) 000-00-01"],
    ["Петрова А. С.", "librarian@zoomag.local", "+7 (900) 000-00-02"],
  ];
  const customers = [];
  for (const [fullName, email, phone] of customersData) {
    const c = await create(token, "customers", {
      fullName, email, phone, deleted: false,
    });
    customers.push(c);
    await create(token, "loyalty_cards", {
      number: `LC-${c.id.slice(0, 8).toUpperCase()}`,
      issuedAt: new Date().toISOString(),
      points: 100,
      level: "Стандарт",
      customer: c.id,
      deleted: false,
    });
  }

  async function upsertUser({ username, email, password, fullName, role, customerId }) {
    const body = {
      username,
      email,
      emailVisibility: true,
      password,
      passwordConfirm: password,
      fullName,
      role,
      customerId: customerId || "",
      verified: true,
    };
    try {
      return await create(token, "users", body);
    } catch (_) {
      // Хук уже мог создать пользователя — обновляем логин/пароль/роль.
      const list = await req(
        `/api/collections/users/records?perPage=1&filter=${encodeURIComponent(`email = "${email}"`)}`,
        { token },
      );
      const existing = list.items?.[0];
      if (!existing) {
        console.warn("user missing", username, email);
        return null;
      }
      return req(`/api/collections/users/records/${existing.id}`, {
        method: "PATCH",
        token,
        body,
      });
    }
  }

  // Ровно по одному пользователю на каждого клиента.
  await upsertUser({
    username: "reader",
    email: "kuznetsova@mail.ru",
    password: "reader123",
    fullName: "Кузнецова М. И.",
    role: "reader",
    customerId: customers[0].id,
  });
  await upsertUser({
    username: "popov",
    email: "popov@mail.ru",
    password: "reader123",
    fullName: "Попов Д. А.",
    role: "reader",
    customerId: customers[1].id,
  });
  await upsertUser({
    username: "vasileva",
    email: "vasileva@mail.ru",
    password: "reader123",
    fullName: "Васильева Е. В.",
    role: "reader",
    customerId: customers[2].id,
  });
  await upsertUser({
    username: "admin",
    email: "shop-admin@zoomag.local",
    password: "admin123",
    fullName: "Администратор",
    role: "admin",
    customerId: customers[3].id,
  });
  await upsertUser({
    username: "librarian",
    email: "librarian@zoomag.local",
    password: "librarian123",
    fullName: "Петрова А. С.",
    role: "librarian",
    customerId: customers[4].id,
  });

  console.log("Seed done:", {
    suppliers: suppliers.length,
    categories: categories.length,
    brands: brands.length,
    products: products.length,
    customers: customers.length,
    users: 5,
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
