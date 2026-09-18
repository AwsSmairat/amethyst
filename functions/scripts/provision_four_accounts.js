/**
 * Create/update the four operational accounts and link driver vehicles.
 *
 * Auth: Firebase CLI login (via firebase-tools ADC) or serviceAccountKey.json
 *
 * Usage (from functions/):
 *   node scripts/provision_four_accounts.js
 */
const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');

const PROJECT_ID = 'amethyst-3328a';

const ACCOUNTS = [
  {
    email: 'sohaib@super.com',
    password: 'Sohaib077@',
    fullName: 'صهيب',
    role: 'super_admin',
  },
  {
    email: 'admin@admin.com',
    password: 'Admin077@',
    fullName: 'مسؤول المحطة',
    role: 'admin',
  },
  {
    email: 'driver@driver.com',
    password: 'Driver077@',
    fullName: 'سائق بينقو',
    role: 'driver',
  },
  {
    email: 'driver2@driver.com',
    password: 'Driver2077@',
    fullName: 'سائق الباص',
    role: 'driver',
  },
];

const VEHICLES = [
  { vehicleNumber: 'بينقو', driverEmail: 'driver@driver.com', notes: 'مركبة بينقو' },
  { vehicleNumber: 'الباص', driverEmail: 'driver2@driver.com', notes: 'مركبة الباص' },
];

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function normalizeName(name) {
  return String(name || '').trim().toLowerCase();
}

async function initAdmin() {
  const keyPath = path.join(__dirname, 'serviceAccountKey.json');
  if (fs.existsSync(keyPath)) {
    admin.initializeApp({
      credential: admin.credential.cert(require(keyPath)),
      projectId: PROJECT_ID,
    });
    return 'service-account';
  }

  const toolsRoot = '/opt/homebrew/lib/node_modules/firebase-tools';
  const { getGlobalDefaultAccount } = require(path.join(toolsRoot, 'lib/auth'));
  const { getCredentialPathAsync } = require(path.join(toolsRoot, 'lib/defaultCredentials'));
  const account = getGlobalDefaultAccount();
  if (!account) {
    throw new Error('Not logged in. Run: firebase login');
  }
  const credPath = await getCredentialPathAsync(account);
  if (!credPath) {
    throw new Error('Could not write Firebase CLI credentials');
  }
  process.env.GOOGLE_APPLICATION_CREDENTIALS = credPath;
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
  });
  return 'firebase-cli';
}

async function upsertAuthUser(spec) {
  const auth = admin.auth();
  const email = normalizeEmail(spec.email);
  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, {
      password: spec.password,
      displayName: spec.fullName,
      disabled: false,
    });
    return { uid: existing.uid, action: 'updated' };
  } catch (err) {
    if (err.code !== 'auth/user-not-found') {
      throw err;
    }
    const created = await auth.createUser({
      email,
      password: spec.password,
      displayName: spec.fullName,
      disabled: false,
    });
    return { uid: created.uid, action: 'created' };
  }
}

async function upsertProfile(uid, spec) {
  const db = admin.firestore();
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const payload = {
    fullName: spec.fullName,
    email: normalizeEmail(spec.email),
    role: spec.role,
    isActive: true,
    phone: null,
    updatedAt: now,
  };
  if (snap.exists) {
    await ref.set(payload, { merge: true });
    return 'updated';
  }
  await ref.set({ ...payload, createdAt: now });
  return 'created';
}

async function linkVehicles(emailToUid) {
  const db = admin.firestore();
  const snap = await db.collection('vehicles').where('isActive', '==', true).get();
  const existing = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const results = [];
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const spec of VEHICLES) {
    const driverId = emailToUid[normalizeEmail(spec.driverEmail)];
    if (!driverId) {
      results.push({ vehicleNumber: spec.vehicleNumber, action: 'skipped' });
      continue;
    }
    const found =
      existing.find((v) => v.driverId === driverId) ||
      existing.find(
        (v) => normalizeName(v.vehicleNumber) === normalizeName(spec.vehicleNumber),
      );
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
    existing.push({ id: ref.id, vehicleNumber: spec.vehicleNumber, driverId });
    results.push({
      vehicleNumber: spec.vehicleNumber,
      id: ref.id,
      driverId,
      action: 'created',
    });
  }
  return results;
}

async function main() {
  const mode = await initAdmin();
  const emailToUid = {};
  const users = [];

  for (const spec of ACCOUNTS) {
    const authResult = await upsertAuthUser(spec);
    const profileAction = await upsertProfile(authResult.uid, spec);
    emailToUid[normalizeEmail(spec.email)] = authResult.uid;
    users.push({
      email: spec.email,
      role: spec.role,
      uid: authResult.uid,
      auth: authResult.action,
      profile: profileAction,
    });
  }

  const vehicles = await linkVehicles(emailToUid);
  console.log(JSON.stringify({ ok: true, mode, users, vehicles }, null, 2));
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
