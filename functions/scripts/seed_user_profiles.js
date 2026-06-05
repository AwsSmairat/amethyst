/**
 * One-time bootstrap: create Firestore users/{uid} for existing Auth accounts.
 *
 * Usage (from repo root):
 *   firebase use amethyst-3328a
 *   cd functions && node scripts/seed_user_profiles.js
 *
 * Requires Application Default Credentials, e.g.:
 *   gcloud auth application-default login
 * or a service account via GOOGLE_APPLICATION_CREDENTIALS.
 */
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const PROJECT_ID = 'amethyst-3328a';

/** @type {Record<string, { fullName: string, role: string }>} */
const PROFILE_BY_EMAIL = {
  'sohaib@super.com': { fullName: 'صهيب', role: 'super_admin' },
  'admin@admin.com': { fullName: 'مسؤول المحطة', role: 'admin' },
  'driver@driver.com': { fullName: 'سائق بينقو', role: 'driver' },
  'driver2@driver.com': { fullName: 'سائق الباص', role: 'driver' },
};

const keyPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  process.argv[2] ||
  path.join(__dirname, 'serviceAccountKey.json');

if (fs.existsSync(keyPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
    projectId: PROJECT_ID,
  });
} else {
  console.error(
    'Missing credentials. Download a service account key from Firebase Console\n' +
      '(Project settings → Service accounts → Generate new private key),\n' +
      'save it as functions/scripts/serviceAccountKey.json, then run:\n' +
      '  npm run seed-profiles\n' +
      '\nOr call the deployed bootstrap function:\n' +
      '  curl -X POST https://us-central1-amethyst-3328a.cloudfunctions.net/bootstrapUserProfiles',
  );
  process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

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

async function seedProfiles() {
  const authUsers = await listAllAuthUsers();
  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const user of authUsers) {
    const email = (user.email || '').trim().toLowerCase();
    const spec = PROFILE_BY_EMAIL[email];
    if (!spec) {
      console.log(`skip  ${email || user.uid} (no role mapping)`);
      skipped += 1;
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
      console.log(`update ${email} -> users/${user.uid} (${spec.role})`);
      updated += 1;
    } else {
      await ref.set({
        ...payload,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`create ${email} -> users/${user.uid} (${spec.role})`);
      created += 1;
    }
  }

  console.log(`\nDone: ${created} created, ${updated} updated, ${skipped} skipped.`);
}

seedProfiles().catch((err) => {
  console.error(err);
  process.exit(1);
});
