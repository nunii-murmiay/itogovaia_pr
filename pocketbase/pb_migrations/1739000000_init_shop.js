/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    const users = app.findCollectionByNameOrId("users");
    users.fields.add(
      new TextField({ name: "username", required: true, unique: true, min: 3, max: 40 }),
    );
    users.fields.add(
      new TextField({ name: "fullName", required: true, min: 2, max: 120 }),
    );
    users.fields.add(
      new SelectField({
        name: "role",
        required: true,
        maxSelect: 1,
        values: ["reader", "librarian", "admin"],
      }),
    );
    users.fields.add(new TextField({ name: "customerId", required: false, max: 32 }));
    users.listRule =
      '@request.auth.id != "" && (@request.auth.role = "admin" || id = @request.auth.id)';
    users.viewRule =
      '@request.auth.id != "" && (@request.auth.role = "admin" || id = @request.auth.id)';
    users.createRule = "";
    users.updateRule =
      '@request.auth.id != "" && (@request.auth.role = "admin" || id = @request.auth.id)';
    users.deleteRule = '@request.auth.role = "admin"';
    // Вход по username — через /api/shop/login (хук). identityFields=email по умолчанию.
    app.save(users);

    const staff =
      '@request.auth.role = "librarian" || @request.auth.role = "admin"';
    const authed = '@request.auth.id != ""';

    function softBase(name, addFields) {
      const c = new Collection({
        type: "base",
        name: name,
        listRule: authed,
        viewRule: authed,
        createRule: staff,
        updateRule: staff,
        deleteRule: '@request.auth.role = "admin"',
      });
      addFields(c);
      c.fields.add(new BoolField({ name: "deleted", required: false }));
      c.fields.add(new DateField({ name: "deletedAt", required: false }));
      app.save(c);
      const saved = app.findCollectionByNameOrId(name);
      saved.listRule = authed;
      saved.viewRule = authed;
      saved.createRule = staff;
      saved.updateRule = staff;
      saved.deleteRule = '@request.auth.role = "admin"';
      app.save(saved);
      return saved;
    }

    softBase("suppliers", (c) => {
      c.fields.add(new TextField({ name: "name", required: true, min: 2, max: 120 }));
      c.fields.add(new TextField({ name: "country", required: true, min: 2, max: 80 }));
      c.fields.add(new TextField({ name: "contactPerson", required: true, min: 2, max: 120 }));
      c.fields.add(new TextField({ name: "phone", required: true, min: 5, max: 40 }));
      c.fields.add(new EmailField({ name: "email", required: true }));
      c.fields.add(new NumberField({ name: "rating", required: true, min: 1, max: 5 }));
    });

    softBase("categories", (c) => {
      c.fields.add(new TextField({ name: "name", required: true, min: 2, max: 80 }));
      c.fields.add(new TextField({ name: "description", required: false, max: 500 }));
      c.fields.add(new TextField({ name: "iconName", required: false, max: 40 }));
    });

    const suppliers = app.findCollectionByNameOrId("suppliers");
    softBase("brands", (c) => {
      c.fields.add(new TextField({ name: "name", required: true, min: 2, max: 120 }));
      c.fields.add(new TextField({ name: "country", required: true, min: 2, max: 80 }));
      c.fields.add(new TextField({ name: "description", required: false, max: 500 }));
      c.fields.add(
        new RelationField({
          name: "suppliers",
          required: false,
          collectionId: suppliers.id,
          maxSelect: 50,
          cascadeDelete: false,
        }),
      );
    });

    const brands = app.findCollectionByNameOrId("brands");
    const categories = app.findCollectionByNameOrId("categories");
    softBase("products", (c) => {
      c.fields.add(new TextField({ name: "name", required: true, min: 2, max: 160 }));
      c.fields.add(new TextField({ name: "sku", required: true, min: 3, max: 40 }));
      c.fields.add(new NumberField({ name: "price", required: true, min: 0.01 }));
      c.fields.add(new NumberField({ name: "stock", required: true, min: 0 }));
      c.fields.add(new NumberField({ name: "rating", required: true, min: 1, max: 5 }));
      c.fields.add(
        new RelationField({
          name: "supplier",
          required: true,
          collectionId: suppliers.id,
          maxSelect: 1,
          cascadeDelete: false,
        }),
      );
      c.fields.add(
        new RelationField({
          name: "brands",
          required: true,
          collectionId: brands.id,
          maxSelect: 20,
          cascadeDelete: false,
        }),
      );
      c.fields.add(
        new RelationField({
          name: "categories",
          required: true,
          collectionId: categories.id,
          maxSelect: 20,
          cascadeDelete: false,
        }),
      );
    });

    softBase("customers", (c) => {
      c.fields.add(new TextField({ name: "fullName", required: true, min: 2, max: 160 }));
      c.fields.add(new EmailField({ name: "email", required: true }));
      c.fields.add(new TextField({ name: "phone", required: true, min: 5, max: 40 }));
    });

    const customers = app.findCollectionByNameOrId("customers");
    softBase("loyalty_cards", (c) => {
      c.fields.add(new TextField({ name: "number", required: true, min: 4, max: 40 }));
      c.fields.add(new DateField({ name: "issuedAt", required: true }));
      c.fields.add(new NumberField({ name: "points", required: true, min: 0 }));
      c.fields.add(
        new SelectField({
          name: "level",
          required: true,
          maxSelect: 1,
          values: ["Стандарт", "Серебро", "Золото", "Платина"],
        }),
      );
      c.fields.add(
        new RelationField({
          name: "customer",
          required: true,
          collectionId: customers.id,
          maxSelect: 1,
          cascadeDelete: true,
        }),
      );
    });

    softBase("sales", (c) => {
      c.fields.add(
        new RelationField({
          name: "customer",
          required: true,
          collectionId: customers.id,
          maxSelect: 1,
          cascadeDelete: false,
        }),
      );
      c.fields.add(new NumberField({ name: "total", required: true, min: 0 }));
      c.fields.add(new NumberField({ name: "pointsEarned", required: false, min: 0 }));
    });

    const products = app.findCollectionByNameOrId("products");
    const sales = app.findCollectionByNameOrId("sales");
    softBase("sale_items", (c) => {
      c.fields.add(
        new RelationField({
          name: "sale",
          required: true,
          collectionId: sales.id,
          maxSelect: 1,
          cascadeDelete: true,
        }),
      );
      c.fields.add(
        new RelationField({
          name: "product",
          required: true,
          collectionId: products.id,
          maxSelect: 1,
          cascadeDelete: false,
        }),
      );
      c.fields.add(new NumberField({ name: "quantity", required: true, min: 1 }));
      c.fields.add(new NumberField({ name: "unitPrice", required: true, min: 0 }));
    });
  },
  (app) => {
    for (const name of [
      "sale_items",
      "sales",
      "loyalty_cards",
      "products",
      "brands",
      "categories",
      "suppliers",
      "customers",
    ]) {
      try {
        app.delete(app.findCollectionByNameOrId(name));
      } catch (_) {}
    }
  },
);
