const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
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
