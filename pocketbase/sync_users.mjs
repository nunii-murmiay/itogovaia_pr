/**
 * Досоздаёт учётки покупателей для клиентов без пользователя.
 * Запуск при уже заполненной базе: node sync_users.mjs
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
  const data = await res.json().catch(() => null);
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}: ${JSON.stringify(data)}`);
  return data;
}

async function main() {
  const auth = await req("/api/collections/_superusers/auth-with-password", {
    method: "POST",
    body: { identity: ADMIN_EMAIL, password: ADMIN_PASS },
  });
  const token = auth.token;
  const customers = await req("/api/collections/customers/records?perPage=200", { token });
  const users = await req("/api/collections/users/records?perPage=200", { token });
  const byCustomer = new Set(
    (users.items || []).map((u) => u.customerId).filter(Boolean),
  );
  const byEmail = new Set((users.items || []).map((u) => String(u.email || "").toLowerCase()));

  let created = 0;
  for (const c of customers.items || []) {
    if (c.deleted) continue;
    if (byCustomer.has(c.id)) continue;
    const email = String(c.email || "").toLowerCase();
    if (!email || byEmail.has(email)) continue;
    let username = email.split("@")[0].replace(/[^a-zA-Z0-9_]/g, "_").slice(0, 40);
    if (username.length < 3) username = `buyer_${c.id.slice(0, 6)}`;
    try {
      await req("/api/collections/users/records", {
        method: "POST",
        token,
        body: {
          username,
          email,
          emailVisibility: true,
          password: "reader123",
          passwordConfirm: "reader123",
          fullName: c.fullName,
          role: "reader",
          customerId: c.id,
          verified: true,
        },
      });
      created++;
      console.log("user for", c.fullName, "→", username);
    } catch (e) {
      console.warn(c.email, e.message);
    }
  }

  const users2 = await req("/api/collections/users/records?perPage=200", { token });
  const cust2 = await req("/api/collections/customers/records?perPage=200&filter=deleted%3Dfalse", { token });
  console.log("done. created=", created, "users=", users2.totalItems, "customers=", cust2.totalItems);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
