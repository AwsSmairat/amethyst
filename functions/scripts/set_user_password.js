/**
 * Set a Firebase Auth user password by email (Admin SDK).
 *
 * Usage:
 *   node scripts/set_user_password.js sohaib@super.com 'Sohaib077@' ./scripts/serviceAccountKey.json
 *
 * Download the key from:
 *   Firebase Console → Project settings → Service accounts → Generate new private key
 * Save it as: functions/scripts/serviceAccountKey.json
 */
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const PROJECT_ID = 'amethyst-3328a';

const email = String(process.argv[2] || '').trim().toLowerCase();
const password = String(process.argv[3] || '');
const keyArg =
  process.argv[4] ||
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'serviceAccountKey.json');

if (!email || !password) {
  console.error(
    "Usage: node scripts/set_user_password.js <email> <password> [serviceAccountKey.json]",
  );
  process.exit(1);
}

const keyPath = path.resolve(keyArg);

if (!fs.existsSync(keyPath)) {
  console.error(
    `Service account key not found:\n  ${keyPath}\n\n` +
      '1) Open Firebase Console → Project settings → Service accounts\n' +
      '2) Click "Generate new private key"\n' +
      '3) Save the file as:\n' +
      `   ${path.join(__dirname, 'serviceAccountKey.json')}\n` +
      '4) Re-run this command.',
  );
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
} catch (err) {
  console.error(`Invalid service account JSON at ${keyPath}: ${err.message}`);
  process.exit(1);
}

if (!serviceAccount.client_email || !serviceAccount.private_key) {
  console.error(
    `Invalid service account file (missing client_email/private_key): ${keyPath}`,
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id || PROJECT_ID,
});

admin
  .auth()
  .getUserByEmail(email)
  .then((user) => admin.auth().updateUser(user.uid, { password }).then(() => user))
  .then((user) => {
    console.log(
      JSON.stringify({
        ok: true,
        email,
        uid: user.uid,
      }),
    );
  })
  .catch((err) => {
    console.error(err.message || String(err));
    process.exit(1);
  });
