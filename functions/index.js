const admin = require('firebase-admin');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');

setGlobalOptions({ region: 'us-central1' });

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function requireSuperAdmin(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const callerUid = request.auth.uid;
  const callerSnap = await db.collection('users').doc(callerUid).get();
  if (!callerSnap.exists) {
    throw new HttpsError('permission-denied', 'Caller profile not found.');
  }
  const caller = callerSnap.data();
  if (caller.role !== 'super_admin') {
    throw new HttpsError('permission-denied', 'Super admin only.');
  }
  if (caller.isActive !== true) {
    throw new HttpsError('permission-denied', 'Account is inactive.');
  }
  return { callerUid, caller };
}

async function getTargetUser(uid) {
  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'User not found.');
  }
  return { uid, data: snap.data() };
}

/** سرّ استدعاء bootstrap — غيّره في Firebase Console → Functions → Environment variables */
const BOOTSTRAP_SECRET =
  process.env.BOOTSTRAP_SECRET || 'amethyst-3328a-setup';

/** @type {Record<string, { fullName: string, role: string }>} */
const PROFILE_BY_EMAIL = {
  'sohaib@super.com': { fullName: 'صهيب', role: 'super_admin' },
  'admin@admin.com': { fullName: 'مسؤول المحطة', role: 'admin' },
  'driver@driver.com': { fullName: 'سائق بينقو', role: 'driver' },
  'driver2@driver.com': { fullName: 'سائق الباص', role: 'driver' },
};

function requireBootstrapSecret(req, res) {
  const secret =
    req.get('x-bootstrap-secret') || req.query.secret || req.body?.secret;
  if (secret !== BOOTSTRAP_SECRET) {
    res.status(403).json({ error: 'Forbidden — invalid bootstrap secret' });
    return false;
  }
  return true;
}

async function listAllAuthUsers() {
  const users = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    users.push(...result.users);
    pageToken = result.pageToken;
  } while (pageToken);
  return users;
}

async function seedMissingUserProfiles() {
  const authUsers = await listAllAuthUsers();
  const results = [];

  for (const user of authUsers) {
    const email = normalizeEmail(user.email);
    const spec = PROFILE_BY_EMAIL[email];
    if (!spec) {
      results.push({ email, uid: user.uid, action: 'skipped' });
      continue;
    }

    const ref = db.collection('users').doc(user.uid);
    const snap = await ref.get();
    const payload = {
      fullName: spec.fullName,
      email,
      role: spec.role,
      isActive: true,
      phone: user.phoneNumber || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (snap.exists) {
      await ref.set(payload, { merge: true });
      results.push({ email, uid: user.uid, action: 'updated', role: spec.role });
      continue;
    }

    await ref.set({
      ...payload,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    results.push({ email, uid: user.uid, action: 'created', role: spec.role });
  }

  return results;
}

/** منتجات رصيد المحطة + كتالوج التطبيق (مطابقة Flutter). */
const SEED_PRODUCTS = [
  { name: 'Water Carton', unitType: 'carton', price: 180, stationStock: 100 },
  { name: 'Carton Yafa', unitType: 'carton', price: 160, stationStock: 80 },
  { name: 'Shrink Large', unitType: 'carton', price: 140, stationStock: 60 },
  { name: 'Shrink Medium', unitType: 'carton', price: 120, stationStock: 60 },
  { name: 'Shrink Small', unitType: 'carton', price: 100, stationStock: 50 },
  { name: 'Saudi Bottle', unitType: 'bottle', price: 8, stationStock: 40 },
  { name: 'Jordanian Bottle', unitType: 'bottle', price: 8, stationStock: 40 },
  { name: 'Empty Gallon', unitType: 'gallon', price: 15, stationStock: 30 },
  { name: 'Ground Bottle', unitType: 'bottle', price: 5, stationStock: 25 },
  { name: 'Ground Gallon', unitType: 'gallon', price: 10, stationStock: 25 },
  { name: 'Coupon', unitType: 'coupon', price: 12, stationStock: 20 },
  { name: 'Coupon 2', unitType: 'coupon', price: 24, stationStock: 15 },
  { name: 'Coupon 3', unitType: 'coupon', price: 50, stationStock: 10 },
  { name: 'Small Empty Bottle', unitType: 'bottle', price: 5, stationStock: 30 },
  { name: 'Small Empty Gallon', unitType: 'gallon', price: 8, stationStock: 30 },
  { name: 'Water Gallon', unitType: 'gallon', price: 12, stationStock: 80 },
  { name: 'Water Bottle', unitType: 'bottle', price: 25, stationStock: 80 },
  { name: 'جالون صغير', unitType: 'gallon', price: 10, stationStock: 40 },
  { name: 'قاروره صغير', unitType: 'bottle', price: 15, stationStock: 40 },
  { name: 'مهدي متجر', unitType: 'carton', price: 200, stationStock: 0 },
  { name: 'جالون متجر', unitType: 'gallon', price: 12, stationStock: 0 },
  { name: 'قاروره متجر', unitType: 'bottle', price: 25, stationStock: 0 },
  { name: 'مع تعبئة — منتجات ١–٣', unitType: 'piece', price: 0.5, stationStock: 0 },
  { name: 'مع تعبئة — منتجات ٤–٥', unitType: 'piece', price: 0.5, stationStock: 0 },
];

const SEED_VEHICLES = [
  {
    vehicleNumber: 'بينقو',
    driverEmail: 'driver@driver.com',
    notes: 'مركبة بينقو',
  },
  {
    vehicleNumber: 'الباص',
    driverEmail: 'driver2@driver.com',
    notes: 'مركبة الباص',
  },
];

function normalizeName(name) {
  return String(name || '').trim().toLowerCase();
}

async function listActiveProducts() {
  const snap = await db.collection('products').where('isActive', '==', true).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function findProductByName(products, name) {
  const want = normalizeName(name);
  return products.find((p) => normalizeName(p.name) === want) || null;
}

async function seedCatalogProducts() {
  const existing = await listActiveProducts();
  const byName = [...existing];
  const results = [];

  for (const spec of SEED_PRODUCTS) {
    const found = await findProductByName(byName, spec.name);
    const now = admin.firestore.FieldValue.serverTimestamp();
    const stock = spec.stationStock ?? 0;
    if (found) {
      await db.collection('products').doc(found.id).set(
        {
          price: spec.price,
          stationStock: stock,
          updatedAt: now,
        },
        { merge: true },
      );
      results.push({
        name: spec.name,
        id: found.id,
        action: 'updated',
        stationStock: stock,
      });
      continue;
    }
    const ref = db.collection('products').doc();
    await ref.set({
      name: spec.name,
      unitType: spec.unitType,
      price: spec.price,
      stationStock: stock,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    });
    byName.push({ id: ref.id, name: spec.name, unitType: spec.unitType });
    results.push({
      name: spec.name,
      id: ref.id,
      action: 'created',
      stationStock: stock,
    });
  }

  return results;
}

async function uidForEmail(email) {
  const normalized = normalizeEmail(email);
  const authUsers = await listAllAuthUsers();
  const match = authUsers.find((u) => normalizeEmail(u.email) === normalized);
  return match ? match.uid : null;
}

async function seedVehicles() {
  const results = [];
  const snap = await db.collection('vehicles').where('isActive', '==', true).get();
  const existing = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  for (const spec of SEED_VEHICLES) {
    const driverId = await uidForEmail(spec.driverEmail);
    if (!driverId) {
      results.push({
        vehicleNumber: spec.vehicleNumber,
        action: 'skipped',
        reason: `driver not found: ${spec.driverEmail}`,
      });
      continue;
    }

    const found =
      existing.find((v) => v.driverId === driverId) ||
      existing.find(
        (v) => normalizeName(v.vehicleNumber) === normalizeName(spec.vehicleNumber),
      );
    const now = admin.firestore.FieldValue.serverTimestamp();
    const payload = {
      vehicleNumber: spec.vehicleNumber,
      driverId,
      isActive: true,
      notes: spec.notes,
      updatedAt: now,
    };

    if (found) {
      await db.collection('vehicles').doc(found.id).set(payload, { merge: true });
      results.push({
        vehicleNumber: spec.vehicleNumber,
        id: found.id,
        driverId,
        action: 'updated',
      });
      continue;
    }

    const ref = db.collection('vehicles').doc();
    await ref.set({ ...payload, createdAt: now });
    existing.push({ id: ref.id, vehicleNumber: spec.vehicleNumber });
    results.push({
      vehicleNumber: spec.vehicleNumber,
      id: ref.id,
      driverId,
      action: 'created',
    });
  }

  return results;
}

async function seedAppCatalog() {
  const products = await seedCatalogProducts();
  const vehicles = await seedVehicles();
  return { products, vehicles };
}

/** One-time bootstrap: products + vehicles. POST only. */
exports.bootstrapAppCatalog = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'POST only' });
    return;
  }
  if (!requireBootstrapSecret(req, res)) {
    return;
  }

  try {
    const results = await seedAppCatalog();
    res.json({ ok: true, ...results });
  } catch (err) {
    res.status(500).json({ error: err.message || 'Catalog bootstrap failed.' });
  }
});

/** One-time bootstrap: creates users/{uid} for known Auth accounts. POST only. */
exports.bootstrapUserProfiles = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'POST only' });
    return;
  }
  if (!requireBootstrapSecret(req, res)) {
    return;
  }

  try {
    const users = await seedMissingUserProfiles();
    const payload = { ok: true, users };
    if (req.query.all === '1') {
      payload.catalog = await seedAppCatalog();
    }
    res.json(payload);
  } catch (err) {
    res.status(500).json({ error: err.message || 'Bootstrap failed.' });
  }
});

exports.createUserBySuperAdmin = onCall(async (request) => {
  const { callerUid } = await requireSuperAdmin(request);

  const fullName = String(request.data?.fullName || '').trim();
  const email = normalizeEmail(request.data?.email);
  const password = String(request.data?.password || '');
  const phoneRaw = request.data?.phone;
  const phone =
    phoneRaw == null || String(phoneRaw).trim() === ''
      ? null
      : String(phoneRaw).trim();
  const role = String(request.data?.role || '').trim();

  if (fullName.length < 2) {
    throw new HttpsError('invalid-argument', 'Full name is required.');
  }
  if (!isValidEmail(email)) {
    throw new HttpsError('invalid-argument', 'Invalid email.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }
  if (role !== 'admin' && role !== 'driver') {
    throw new HttpsError('invalid-argument', 'Role must be admin or driver.');
  }

  let userRecord;
  try {
    userRecord = await auth.createUser({
      email,
      password,
      displayName: fullName,
      disabled: false,
    });
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'Email already in use.');
    }
    throw new HttpsError('internal', err.message || 'Failed to create auth user.');
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  try {
    await db.collection('users').doc(userRecord.uid).set({
      fullName,
      email,
      phone,
      role,
      isActive: true,
      createdBy: callerUid,
      createdAt: now,
      updatedAt: now,
    });
  } catch (err) {
    await auth.deleteUser(userRecord.uid).catch(() => {});
    throw new HttpsError('internal', 'Failed to create user profile.');
  }

  return { uid: userRecord.uid };
});

exports.setUserActiveStatus = onCall(async (request) => {
  const { callerUid } = await requireSuperAdmin(request);

  const uid = String(request.data?.uid || '').trim();
  const isActive = request.data?.isActive === true;

  if (!uid) {
    throw new HttpsError('invalid-argument', 'User id is required.');
  }
  if (uid === callerUid) {
    throw new HttpsError('failed-precondition', 'Cannot change your own status.');
  }

  const target = await getTargetUser(uid);
  if (target.data.role === 'super_admin') {
    throw new HttpsError('failed-precondition', 'Cannot change super admin status.');
  }

  await auth.updateUser(uid, { disabled: !isActive });
  await db.collection('users').doc(uid).update({
    isActive,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid, isActive };
});

exports.updateUserBySuperAdmin = onCall(async (request) => {
  await requireSuperAdmin(request);

  const uid = String(request.data?.uid || '').trim();
  const fullName = String(request.data?.fullName || '').trim();
  const phoneRaw = request.data?.phone;
  const phone =
    phoneRaw == null || String(phoneRaw).trim() === ''
      ? null
      : String(phoneRaw).trim();
  const role = String(request.data?.role || '').trim();

  if (!uid) {
    throw new HttpsError('invalid-argument', 'User id is required.');
  }
  if (fullName.length < 2) {
    throw new HttpsError('invalid-argument', 'Full name is required.');
  }
  if (role !== 'admin' && role !== 'driver') {
    throw new HttpsError('invalid-argument', 'Role must be admin or driver.');
  }

  const target = await getTargetUser(uid);
  if (target.data.role === 'super_admin') {
    throw new HttpsError('failed-precondition', 'Cannot edit super admin.');
  }

  await db.collection('users').doc(uid).update({
    fullName,
    phone,
    role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid };
});

exports.sendPasswordResetBySuperAdmin = onCall(async (request) => {
  await requireSuperAdmin(request);

  const email = normalizeEmail(request.data?.email);
  if (!isValidEmail(email)) {
    throw new HttpsError('invalid-argument', 'Invalid email.');
  }

  const apiKey =
    process.env.WEB_API_KEY || 'AIzaSyCsuPxGcE6JzibDeIlxvUDMDlZiDlXOUc0';

  const url = `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      requestType: 'PASSWORD_RESET',
      email,
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    const message = body?.error?.message || 'Failed to send password reset email.';
    throw new HttpsError('internal', message);
  }

  return { email, sent: true };
});
