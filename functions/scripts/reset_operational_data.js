/**
 * Reset all operational numbers: delete sales, loads, debts, expenses, movements;
 * zero station stock on all products. Keeps users, vehicles, and product catalog.
 *
 * Usage (from repo root):
 *   firebase use amethyst-3328a
 *   cd functions && node scripts/reset_operational_data.js
 *
 * Or with a service account key:
 *   node scripts/reset_operational_data.js path/to/serviceAccountKey.json
 *
 * Or call the deployed function (after deploy):
 *   curl -X POST "https://us-central1-amethyst-3328a.cloudfunctions.net/resetOperationalData" \
 *     -H "x-bootstrap-secret: YOUR_BOOTSTRAP_SECRET"
 */
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const admin = require('firebase-admin');
const { resetOperationalData } = require('../operational_reset');

const PROJECT_ID = 'amethyst-3328a';

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
  try {
    admin.initializeApp({ projectId: PROJECT_ID });
  } catch (_) {
    // fall through to error below
  }
}

const db = admin.firestore();

function askConfirmation(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

async function main() {
  if (!admin.apps.length) {
    console.error(
      'Missing credentials. Download a service account key from Firebase Console\n' +
        '(Project settings → Service accounts → Generate new private key),\n' +
        'save it as functions/scripts/serviceAccountKey.json, then run:\n' +
        '  npm run reset-data\n' +
        '\nOr deploy and call the cloud function:\n' +
        '  firebase deploy --only functions:resetOperationalData\n' +
        '  curl -X POST https://us-central1-amethyst-3328a.cloudfunctions.net/resetOperationalData \\\n' +
        '    -H "x-bootstrap-secret: YOUR_BOOTSTRAP_SECRET"',
    );
    process.exit(1);
  }

  const confirm = process.argv.includes('--yes')
    ? 'yes'
    : await askConfirmation(
        'This permanently deletes all sales, loads, debts, expenses, and zeros stock.\n' +
          'Users, vehicles, and product catalog are kept. Type "yes" to continue: ',
      );

  if (confirm !== 'yes') {
    console.log('Cancelled.');
    process.exit(0);
  }

  console.log('Resetting operational data...');
  const result = await resetOperationalData(db);
  console.log(JSON.stringify(result, null, 2));
  console.log('\nDone. All application numbers are now zero.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
