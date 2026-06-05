/**
 * Deletes transactional Firestore data and zeros product station stock.
 * Keeps users, vehicles, and product catalog (names/prices).
 */
const admin = require('firebase-admin');

/** @type {readonly string[]} */
const COLLECTIONS_TO_DELETE = [
  'vehicle_sales',
  'vehicle_loads',
  'station_sales',
  'station_debt_entries',
  'expenses',
  'stock_movements',
  'audit_logs',
  'staff_notes',
];

const BATCH_SIZE = 400;

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} collectionPath
 */
async function deleteCollection(db, collectionPath) {
  let deleted = 0;

  while (true) {
    const snap = await db.collection(collectionPath).limit(BATCH_SIZE).get();
    if (snap.empty) {
      break;
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snap.size;
  }

  return deleted;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 */
async function zeroProductStock(db) {
  const snap = await db.collection('products').get();
  if (snap.empty) {
    return { updated: 0 };
  }

  let updated = 0;
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (let i = 0; i < snap.docs.length; i += BATCH_SIZE) {
    const chunk = snap.docs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.set(
        doc.ref,
        {
          stationStock: 0,
          updatedAt: now,
        },
        { merge: true },
      );
    }
    await batch.commit();
    updated += chunk.length;
  }

  return { updated };
}

/**
 * @param {FirebaseFirestore.Firestore} db
 */
async function resetOperationalData(db) {
  const deleted = {};

  for (const name of COLLECTIONS_TO_DELETE) {
    deleted[name] = await deleteCollection(db, name);
  }

  const products = await zeroProductStock(db);

  return {
    deleted,
    products,
    kept: ['users', 'vehicles', 'products (catalog only, stock = 0)'],
  };
}

module.exports = {
  COLLECTIONS_TO_DELETE,
  resetOperationalData,
};
