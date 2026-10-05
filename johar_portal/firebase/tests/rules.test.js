// Security rules tests. Run from firebase/tests:  npm i && npm test
// (needs Java 11+ for the Firestore emulator)
const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, setDoc, updateDoc, collection, query, where, addDoc } = require('firebase/firestore');

let env;
const as = (uid, claims = {}) => env.authenticatedContext(uid, claims).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-johar',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const users = {
      sup: { role: 'supervisor', employer: 'BCCL', status: 'active' },
      insp: { role: 'inspector', status: 'active' },
      adm: { role: 'admin', status: 'active' },
      off: { role: 'inspector', status: 'disabled' },
    };
    for (const [id, u] of Object.entries(users)) await setDoc(doc(db, 'portalUsers', id), u);
    await setDoc(doc(db, 'workers', 'w1'), { employer: 'BCCL', deviceUid: 'phone1', name: 'A' });
    await setDoc(doc(db, 'workers', 'w2'), { employer: 'Bokaro', deviceUid: 'phone2', name: 'B' });
    await setDoc(doc(db, 'attempts', 'a1'), { employer: 'BCCL', workerId: 'w1', deviceUid: 'phone1', totalPercent: 80, passed: true });
    await setDoc(doc(db, 'certificates', 'c1'), { employer: 'BCCL', workerId: 'w1', deviceUid: 'phone1', status: 'active' });
    await setDoc(doc(db, 'certificates', 'c2'), { employer: 'Bokaro', workerId: 'w2', deviceUid: 'phone2', status: 'active' });
  });
});
after(() => env.cleanup());

test('supervisor lists only their own employer', async () => {
  const db = as('sup');
  await assertSucceeds(getDocs(query(collection(db, 'workers'), where('employer', '==', 'BCCL'))));
  await assertFails(getDocs(query(collection(db, 'workers'), where('employer', '==', 'Bokaro'))));
  await assertFails(getDocs(collection(db, 'workers'))); // unfiltered query refused
  await assertSucceeds(getDocs(query(collection(db, 'attempts'), where('employer', '==', 'BCCL'))));
});

test('inspector and admin read everything', async () => {
  await assertSucceeds(getDocs(collection(as('insp'), 'workers')));
  await assertSucceeds(getDocs(collection(as('adm'), 'certificates')));
  await assertSucceeds(getDocs(collection(as('boot', { admin: true }), 'attempts')));
});

test('disabled or unknown portal users read nothing', async () => {
  await assertFails(getDocs(collection(as('off'), 'workers')));
  await assertFails(getDocs(collection(as('stranger'), 'workers')));
});

test('only admin/inspector can cancel, and only the status fields', async () => {
  await assertFails(updateDoc(doc(as('sup'), 'certificates', 'c1'), { status: 'revoked', revokedReason: 'x' }));
  await assertSucceeds(updateDoc(doc(as('insp'), 'certificates', 'c1'), { status: 'revoked', revokedReason: 'x' }));
  await assertFails(updateDoc(doc(as('insp'), 'certificates', 'c2'), { score: 100 }));
  await assertFails(updateDoc(doc(as('insp'), 'certificates', 'c2'), { status: 'bogus' }));
});

test('any signed-in verifier can look up one certificate by ID', async () => {
  await assertSucceeds(getDoc(doc(as('sup'), 'certificates', 'c2')));
});

test('access requests: pending only, no self-promotion', async () => {
  const me = as('new1');
  await assertFails(setDoc(doc(me, 'portalUsers', 'new1'), { role: 'admin', status: 'active' }));
  await assertSucceeds(setDoc(doc(me, 'portalUsers', 'new1'), { role: 'none', status: 'pending', name: 'N' }));
  await assertFails(updateDoc(doc(me, 'portalUsers', 'new1'), { role: 'admin' }));
  await assertSucceeds(updateDoc(doc(me, 'portalUsers', 'new1'), { name: 'New name' }));
  await assertFails(setDoc(doc(me, 'portalUsers', 'someoneElse'), { role: 'none', status: 'pending' }));
  await assertSucceeds(updateDoc(doc(as('adm'), 'portalUsers', 'new1'), { role: 'supervisor', employer: 'BCCL', status: 'active' }));
  await assertFails(getDocs(collection(as('sup'), 'portalUsers')));
});

test('audit log is append-only and signed by the writer', async () => {
  await assertSucceeds(addDoc(collection(as('insp'), 'auditLog'), { action: 'revokeCertificate', by: 'insp' }));
  await assertFails(addDoc(collection(as('insp'), 'auditLog'), { action: 'x', by: 'someoneElse' }));
  await assertFails(getDocs(collection(as('insp'), 'auditLog')));
  await assertSucceeds(getDocs(collection(as('adm'), 'auditLog')));
});
