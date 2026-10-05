// Firebase implementation of the portal backend.
import { firebaseConfig } from './config.js';

const V = '10.12.2';
const base = `https://www.gstatic.com/firebasejs/${V}`;
let A, F, auth, db;

/** Converts Firestore Timestamps to ISO strings so the rest of the portal handles plain values. */
const norm = (snap) => {
  const d = snap.data();
  for (const k of Object.keys(d)) if (d[k]?.toDate) d[k] = d[k].toDate().toISOString();
  return { id: snap.id, ...d };
};

export const backend = {
  demo: false,

  async init() {
    const [{ initializeApp }, auth_, fs] = await Promise.all([
      import(`${base}/firebase-app.js`), import(`${base}/firebase-auth.js`), import(`${base}/firebase-firestore.js`),
    ]);
    A = auth_; F = fs;
    const app = initializeApp(firebaseConfig);
    auth = A.getAuth(app);
    db = F.getFirestore(app);
  },

  onAuth(cb) { return A.onAuthStateChanged(auth, cb); },

  async signInGoogle() {
    const provider = new A.GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });
    try {
      await A.signInWithPopup(auth, provider);
    } catch (e) {
      // Popups are often blocked on phones: fall back to a full-page redirect.
      if (e.code === 'auth/popup-blocked' || e.code === 'auth/operation-not-supported-in-this-environment') {
        await A.signInWithRedirect(auth, provider);
      } else throw e;
    }
  },
  signInEmail(email, password) { return A.signInWithEmailAndPassword(auth, email, password); },
  signOut() { return A.signOut(auth); },

  async claims(user) { return (await user.getIdTokenResult(true)).claims; },

  async getPortalUser(uid) {
    const s = await F.getDoc(F.doc(db, 'portalUsers', uid));
    return s.exists() ? norm(s) : null;
  },
  requestAccess(uid, data) {
    return F.setDoc(F.doc(db, 'portalUsers', uid), { ...data, role: 'none', status: 'pending', createdAt: F.serverTimestamp() });
  },
  touchLogin(uid, patch) {
    return F.updateDoc(F.doc(db, 'portalUsers', uid), { ...patch, lastLoginAt: F.serverTimestamp() }).catch(() => {});
  },

  /** Reads a collection. Supervisors must pass `employer` so the query matches the security rules. */
  async list(name, { employer } = {}) {
    const ref = F.collection(db, name);
    const q = employer ? F.query(ref, F.where('employer', '==', employer)) : ref;
    return (await F.getDocs(q)).docs.map(norm);
  },
  async getCertificate(id) {
    const s = await F.getDoc(F.doc(db, 'certificates', id));
    return s.exists() ? norm(s) : null;
  },
  updateCertificate(id, patch) {
    return F.updateDoc(F.doc(db, 'certificates', id), { ...patch, ...(patch.status === 'revoked' ? { revokedAt: F.serverTimestamp() } : { revokedAt: null }) });
  },

  // --- Admin ---
  async listPortalUsers() { return (await F.getDocs(F.collection(db, 'portalUsers'))).docs.map(norm); },
  updatePortalUser(uid, patch) { return F.updateDoc(F.doc(db, 'portalUsers', uid), patch); },
  deletePortalUser(uid) { return F.deleteDoc(F.doc(db, 'portalUsers', uid)); },
  audit(entry) { return F.addDoc(F.collection(db, 'auditLog'), { ...entry, at: F.serverTimestamp() }).catch(() => {}); },
  async listAudit(max = 100) {
    const q = F.query(F.collection(db, 'auditLog'), F.orderBy('at', 'desc'), F.limit(max));
    return (await F.getDocs(q)).docs.map(norm);
  },
};
