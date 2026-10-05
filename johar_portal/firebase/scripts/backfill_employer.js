// One-time: copy each worker's employer onto attempts and memory checks that
// were uploaded before the app started including it. Without this,
// supervisors cannot see older records.
//
//   cd firebase/scripts && npm i firebase-admin
//   GOOGLE_APPLICATION_CREDENTIALS=service-account.json node backfill_employer.js
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

(async () => {
  const workers = new Map((await db.collection('workers').get()).docs.map((d) => [d.id, d.get('employer') || '']));
  for (const name of ['attempts', 'refreshers']) {
    const snap = await db.collection(name).get();
    let writer = db.bulkWriter(), n = 0;
    for (const d of snap.docs) {
      if (d.get('employer') !== undefined) continue;
      writer.update(d.ref, { employer: workers.get(d.get('workerId')) ?? '' });
      n++;
    }
    await writer.close();
    console.log(`${name}: updated ${n} of ${snap.size}`);
  }
})();
