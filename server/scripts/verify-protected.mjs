#!/usr/bin/env node
/**
 * End-to-end checks: auth, RBAC, driver data isolation.
 * Requires: API running + seeded DB (see README).
 *
 *   BASE_URL=http://localhost:4000 npm run verify:protected
 *
 * Optional env overrides:
 *   E2E_SUPER_EMAIL / E2E_SUPER_PASSWORD
 *   E2E_ADMIN_EMAIL / E2E_ADMIN_PASSWORD
 *   E2E_DRIVER_EMAIL / E2E_DRIVER_PASSWORD
 */

const base = (process.env.BASE_URL || 'http://localhost:4000').replace(/\/$/, '');
const api = `${base}/api`;

const CRED = {
  super_admin: {
    email: process.env.E2E_SUPER_EMAIL || 'sohaib@amethyst.local',
    password: process.env.E2E_SUPER_PASSWORD || 'sohaib123',
  },
  admin: {
    email: process.env.E2E_ADMIN_EMAIL || 'admin@amethyst.local',
    password: process.env.E2E_ADMIN_PASSWORD || 'Admin123!',
  },
  driver: {
    email: process.env.E2E_DRIVER_EMAIL || 'driver1@amethyst.local',
    password: process.env.E2E_DRIVER_PASSWORD || 'Driver123!',
  },
};

async function login(email, password) {
  const r = await fetch(`${api}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const json = await r.json().catch(() => ({}));
  if (!r.ok || !json?.data?.token) {
    throw new Error(`Login failed (${email}): HTTP ${r.status} ${JSON.stringify(json)}`);
  }
  return json.data.token;
}

async function authFetch(path, token, opts = {}) {
  const url = `${api}${path.startsWith('/') ? path : `/${path}`}`;
  const r = await fetch(url, {
    ...opts,
    headers: {
      Accept: 'application/json',
      ...(opts.body ? { 'Content-Type': 'application/json' } : {}),
      ...opts.headers,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
  const text = await r.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = text;
  }
  return { status: r.status, json };
}

function ok(name) {
  console.log('✓', name);
}

function fail(name, detail) {
  console.error('✗', name, detail);
}

async function main() {
  let failed = 0;
  const must = (cond, name, detail) => {
    if (!cond) {
      fail(name, detail);
      failed++;
      return false;
    }
    ok(name);
    return true;
  };

  let tSuper;
  let tAdmin;
  let tDriver;
  try {
    tSuper = await login(CRED.super_admin.email, CRED.super_admin.password);
    tAdmin = await login(CRED.admin.email, CRED.admin.password);
    tDriver = await login(CRED.driver.email, CRED.driver.password);
  } catch (e) {
    console.error(e.message);
    console.error('\nIs the server running and the database seeded?');
    process.exit(1);
  }

  // --- Auth: me ---
  let driverUserId;
  for (const [label, tok] of [
    ['super_admin', tSuper],
    ['admin', tAdmin],
    ['driver', tDriver],
  ]) {
    const { status, json } = await authFetch('/auth/me', tok);
    if (!must(status === 200 && json?.success && json?.data?.id, `GET /auth/me (${label})`, `${status} ${JSON.stringify(json)}`)) {
      continue;
    }
    if (label === 'driver') driverUserId = json.data.id;
  }

  must(driverUserId, 'Driver user id from /auth/me', 'missing');

  // --- Register: forbidden when DB already seeded ---
  const reg = await fetch(`${api}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      fullName: 'E2E',
      phone: '+19998887777',
      email: 'e2e-blocked@local.test',
      password: 'Password123!',
      role: 'super_admin',
    }),
  });
  const regJson = await reg.json().catch(() => ({}));
  must(
    reg.status === 403,
    'POST /auth/register returns 403 when users exist',
    `${reg.status} ${JSON.stringify(regJson)}`
  );

  // --- Users RBAC ---
  const adminPostUser = await authFetch('/users', tAdmin, {
    method: 'POST',
    body: JSON.stringify({
      fullName: 'Should Fail',
      phone: '+18888888888',
      email: 'should-fail@local.test',
      password: 'Password123!',
      role: 'driver',
    }),
  });
  must(
    adminPostUser.status === 403,
    'Admin cannot POST /users (super_admin only)',
    adminPostUser.status
  );

  const driverListUsers = await authFetch('/users', tDriver);
  must(driverListUsers.status === 403, 'Driver cannot GET /users', driverListUsers.status);

  const adminDeleteUser = await authFetch(
    '/users/00000000-0000-0000-0000-000000000001',
    tAdmin,
    { method: 'DELETE' }
  );
  must(
    adminDeleteUser.status === 403,
    'Admin cannot DELETE /users (super_admin only)',
    adminDeleteUser.status
  );

  const superListUsers = await authFetch('/users?page=1&limit=5', tSuper);
  must(superListUsers.status === 200, 'Super admin can GET /users', superListUsers.status);

  // --- Dashboard RBAC ---
  must(
    (await authFetch('/dashboard/super-admin', tSuper)).status === 200,
    'super_admin GET /dashboard/super-admin',
    ''
  );
  must(
    (await authFetch('/dashboard/super-admin', tAdmin)).status === 403,
    'admin cannot GET /dashboard/super-admin',
    ''
  );
  must(
    (await authFetch('/dashboard/super-admin', tDriver)).status === 403,
    'driver cannot GET /dashboard/super-admin',
    ''
  );
  must(
    (await authFetch('/dashboard/admin', tAdmin)).status === 200,
    'admin GET /dashboard/admin',
    ''
  );
  must(
    (await authFetch('/dashboard/admin', tSuper)).status === 200,
    'super_admin GET /dashboard/admin',
    ''
  );
  must(
    (await authFetch('/dashboard/driver', tDriver)).status === 200,
    'driver GET /dashboard/driver',
    ''
  );
  must(
    (await authFetch('/dashboard/driver', tSuper)).status === 403,
    'super_admin cannot GET /dashboard/driver',
    ''
  );
  must(
    (await authFetch('/dashboard/driver', tAdmin)).status === 403,
    'admin cannot GET /dashboard/driver',
    ''
  );

  // --- Station sales: driver forbidden ---
  const driverStation = await authFetch('/station-sales', tDriver);
  must(driverStation.status === 403, 'Driver cannot GET /station-sales', driverStation.status);

  // --- Products: any authenticated ---
  must(
    (await authFetch('/products?page=1&limit=5', tDriver)).status === 200,
    'Driver can GET /products',
    ''
  );

  // --- Vehicle sales: driver isolation ---
  const vs = await authFetch('/vehicle-sales?limit=100', tDriver);
  if (vs.status === 200) {
    const items = vs.json?.data?.items ?? [];
    const leaked = items.filter((row) => row.driverId && row.driverId !== driverUserId);
    must(leaked.length === 0, 'Vehicle sales list: only authenticated driver', leaked.length);
  } else {
    fail('Driver GET /vehicle-sales', vs.status);
    failed++;
  }

  // --- Expenses: driver isolation ---
  const ex = await authFetch('/expenses?limit=100', tDriver);
  if (ex.status === 200) {
    const items = ex.json?.data?.items ?? [];
    const leaked = items.filter((row) => row.driverId && row.driverId !== driverUserId);
    must(leaked.length === 0, 'Expenses list: only authenticated driver', leaked.length);
  } else {
    fail('Driver GET /expenses', ex.status);
    failed++;
  }

  // --- Vehicle loads: driver isolation ---
  const vl = await authFetch('/vehicle-loads?limit=100', tDriver);
  if (vl.status === 200) {
    const items = vl.json?.data?.items ?? [];
    const leaked = items.filter((row) => row.driverId && row.driverId !== driverUserId);
    must(leaked.length === 0, 'Vehicle loads list: only authenticated driver', leaked.length);
  } else {
    fail('Driver GET /vehicle-loads', vl.status);
    failed++;
  }

  if (failed) {
    console.error(`\n${failed} check(s) failed.`);
    process.exit(1);
  }
  console.log('\nAll protected-route checks passed.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
