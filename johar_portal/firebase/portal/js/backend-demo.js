// Demo backend: realistic sample data in memory, no Firebase needed.
// Open the portal with ?demo=1 (admin), ?demo=inspector, ?demo=supervisor,
// ?demo=pending (access-request screen) or ?demo=login (sign-in screen first).
import { demoKeyPair } from './crypto.js';

const FIRST = ['Sunita', 'Ramesh', 'Birsa', 'Phulmani', 'Anil', 'Kavita', 'Manoj', 'Sita', 'Jitendra', 'Laxmi', 'Rajesh', 'Pooja',
  'Suresh', 'Anita', 'Deepak', 'Meena', 'Vijay', 'Rekha', 'Santosh', 'Geeta', 'Budhan', 'Sukra', 'Dhaneshwar', 'Salomi', 'Mangal'];
const LAST = ['Murmu', 'Hansda', 'Tudu', 'Soren', 'Oraon', 'Kisku', 'Mahato', 'Besra', 'Munda', 'Hembrom', 'Marandi', 'Tirkey',
  'Baskey', 'Lakra', 'Kujur', 'Toppo', 'Minz', 'Ekka', 'Bage', 'Xalxo', 'Gope', 'Sahu'];
const EMPLOYERS = [
  { name: 'BCCL Jharia Colliery', sector: 'coal', code: 'BCCL' },
  { name: 'CCL Piparwar Mine', sector: 'coal', code: 'CCL' },
  { name: 'Bokaro Steel Plant', sector: 'steel', code: 'BSL' },
  { name: 'Jamshedpur Rolling Mill', sector: 'steel', code: 'JRM' },
  { name: 'Koderma Mica Works', sector: 'mica', code: 'KMW' },
];
const MODULE_QUESTIONS = { fire: 8, gas: 8, machinery: 8 };
const PREFIX = { fire: 'f', gas: 'g', machinery: 'm' };
const DAY = 864e5;

function rng(seed) {
  return () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;
}
const uuid = (r) => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
  const v = Math.floor(r() * 16);
  return (c === 'x' ? v : (v & 0x3) | 0x8).toString(16);
});

async function generate() {
  const r = rng(20260929);
  const keys = await demoKeyPair();
  const now = Date.now();
  const workers = [], attempts = [], certificates = [], refreshers = [];

  for (let i = 0; i < 86; i++) {
    const e = EMPLOYERS[Math.floor(r() * EMPLOYERS.length)];
    const ageDays = Math.floor(r() < 0.18 ? r() * 28 : 20 + r() * 400);
    const w = {
      id: uuid(r),
      name: `${FIRST[Math.floor(r() * FIRST.length)]} ${LAST[Math.floor(r() * LAST.length)]}`,
      employeeId: `${e.code}-${4100 + i * 7}`,
      employer: e.name,
      sector: e.sector,
      language: r() < 0.55 ? 'hi' : r() < 0.6 ? 'sat' : 'en',
      createdAt: new Date(now - ageDays * DAY).toISOString(),
    };
    workers.push(w);
    // Skill differs by worker; recent joiners have done less.
    const skill = 0.35 + r() * 0.6;
    for (const m of ['fire', 'gas', 'machinery']) {
      if (r() < (ageDays < 30 ? 0.55 : 0.12)) continue;
      const tries = r() < 0.3 ? 2 : 1;
      let when = now - Math.min(ageDays, 420) * DAY * (0.3 + r() * 0.7);
      for (let k = 0; k < tries; k++) {
        const quiz = Math.round(Math.min(100, 30 + skill * 70 + (r() - 0.5) * 30 + k * 12));
        const ar = Math.round(Math.min(100, 35 + skill * 65 + (r() - 0.5) * 30 + k * 10));
        const total = Math.round(quiz * 0.6 + ar * 0.4);
        const criticalMissed = r() < (1 - skill) * 0.35 ? [`${PREFIX[m]}${1 + Math.floor(r() * 3)}`] : [];
        const passed = total >= 70 && criticalMissed.length === 0;
        const wrong = [];
        for (let q = 1; q <= MODULE_QUESTIONS[m]; q++) if (r() < (1 - skill) * (0.25 + (q % 3) * 0.12)) wrong.push(`${PREFIX[m]}${q}`);
        const id = uuid(r);
        const completedAt = new Date(when).toISOString();
        attempts.push({
          id, workerId: w.id, moduleId: m, employer: w.employer, quizPercent: quiz, arPercent: ar, totalPercent: total, passed,
          criticalMissed, wrongQuestionIds: [...new Set([...wrong, ...criticalMissed])], startedAt: new Date(when - 900e3).toISOString(),
          completedAt, durationSec: 600 + Math.floor(r() * 900), arMode: r() < 0.85 ? 'orientation' : 'touch',
        });
        if (passed) {
          const issuedAt = Math.floor(when / 1000) + 30;
          const expiresAt = issuedAt + 365 * 86400;
          const payload = { v: 1, c: id, w: w.id, n: w.name, e: w.employeeId, m, s: total, i: issuedAt, x: expiresAt };
          certificates.push({
            id, workerId: w.id, employeeId: w.employeeId, employer: w.employer, sector: w.sector, moduleId: m, score: total,
            issuedAt, expiresAt, status: r() < 0.02 ? 'revoked' : 'active', token: keys ? await keys.sign(payload) : `SS1.demo.${id}`,
            ...(r() < 0.02 ? { revokedReason: 'Training done by another person' } : {}),
          });
          if (now - when > 7 * DAY && r() < 0.7) {
            const retained = Math.round(Math.max(20, Math.min(100, quiz - (1 - skill) * 45 + (r() - 0.4) * 20)));
            refreshers.push({ id: uuid(r), workerId: w.id, moduleId: m, employer: w.employer, sourceAttemptId: id,
              originalPercent: quiz, percent: retained, daysAfter: 7 + Math.floor(r() * 5), takenAt: new Date(when + 8 * DAY).toISOString() });
          }
          break;
        }
        when += (2 + r() * 10) * DAY;
      }
    }
  }
  const users = [
    { id: 'demo-admin', name: 'Anjali Kumari', email: 'anjali.k@jharkhand.gov.in', role: 'admin', status: 'active', organisation: 'Directorate of Industrial Safety', createdAt: new Date(now - 90 * DAY).toISOString(), lastLoginAt: new Date(now - 3600e3).toISOString() },
    { id: 'demo-inspector', name: 'R. K. Singh', email: 'rk.singh@dgms.gov.in', role: 'inspector', status: 'active', organisation: 'DGMS Dhanbad', createdAt: new Date(now - 60 * DAY).toISOString(), lastLoginAt: new Date(now - 2 * DAY).toISOString() },
    { id: 'demo-supervisor', name: 'Prakash Mahto', email: 'prakash.m@bccl.in', role: 'supervisor', employer: 'BCCL Jharia Colliery', status: 'active', organisation: 'BCCL', createdAt: new Date(now - 40 * DAY).toISOString(), lastLoginAt: new Date(now - DAY).toISOString() },
    { id: 'req-1', name: 'Neha Oraon', email: 'neha.oraon@bokarosteel.in', role: 'none', status: 'pending', requestedRole: 'supervisor', requestedEmployer: 'Bokaro Steel Plant', organisation: 'SAIL Bokaro', phone: '+91 94311 00000', note: 'Safety officer, blast furnace section', createdAt: new Date(now - 2 * DAY).toISOString() },
    { id: 'req-2', name: 'Amit Pandey', email: 'amit.p@gmail.com', role: 'none', status: 'pending', requestedRole: 'inspector', organisation: 'Labour Dept.', createdAt: new Date(now - 5 * 3600e3).toISOString() },
  ];
  const audit = [
    { id: 'a1', action: 'approveUser', targetLabel: 'Prakash Mahto', byName: 'Anjali Kumari', at: new Date(now - 40 * DAY).toISOString(), details: 'supervisor · BCCL Jharia Colliery' },
    { id: 'a2', action: 'revokeCertificate', targetLabel: certificates.find((c) => c.status === 'revoked')?.id.slice(0, 8).toUpperCase() ?? 'A1B2C3D4', byName: 'R. K. Singh', at: new Date(now - 6 * DAY).toISOString(), details: 'Training done by another person' },
  ];
  return { data: { workers, attempts, certificates, refreshers }, users, audit, pubB64: keys?.pubB64 };
}

export function makeDemoBackend(mode) {
  let db, cb, current = null;
  const role = ['inspector', 'supervisor', 'pending'].includes(mode) ? mode : 'admin';
  const demoUser = { uid: `demo-${role}`, displayName: role === 'pending' ? 'New Officer' : { admin: 'Anjali Kumari', inspector: 'R. K. Singh', supervisor: 'Prakash Mahto' }[role], email: 'demo@johar.app', photoURL: null };
  const wait = (ms = 120) => new Promise((r) => setTimeout(r, ms));

  return {
    demo: true,
    get publicKey() { return db?.pubB64; },
    async init() { db = await generate(); },
    onAuth(fn) { cb = fn; setTimeout(() => cb(mode === 'login' ? null : (current = demoUser)), 50); return () => {}; },
    async signInGoogle() { await wait(300); cb((current = { ...demoUser, uid: 'demo-admin', displayName: 'Anjali Kumari' })); },
    async signInEmail() { return this.signInGoogle(); },
    async signOut() { current = null; cb(null); },
    async claims() { return {}; },
    async getPortalUser(uid) {
      if (role === 'pending' && uid === 'demo-pending') return null;
      return db.users.find((u) => u.id === uid) ?? null;
    },
    async requestAccess(uid, data) { db.users.push({ id: uid, ...data, role: 'none', status: 'pending', createdAt: new Date().toISOString() }); },
    async touchLogin() {},
    async list(name, { employer } = {}) {
      await wait();
      const rows = db.data[name] ?? [];
      return structuredClone(employer ? rows.filter((x) => x.employer === employer) : rows);
    },
    async getCertificate(id) { return structuredClone(db.data.certificates.find((c) => c.id === id) ?? null); },
    async updateCertificate(id, patch) {
      await wait();
      Object.assign(db.data.certificates.find((c) => c.id === id), patch, { revokedAt: patch.status === 'revoked' ? new Date().toISOString() : null });
    },
    async listPortalUsers() { await wait(); return structuredClone(db.users); },
    async updatePortalUser(uid, patch) { Object.assign(db.users.find((u) => u.id === uid), patch); },
    async deletePortalUser(uid) { db.users = db.users.filter((u) => u.id !== uid); },
    async audit(entry) { db.audit.unshift({ id: `a${Date.now()}`, ...entry, at: new Date().toISOString() }); },
    async listAudit() { return structuredClone(db.audit); },
  };
}
