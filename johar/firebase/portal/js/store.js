// Session, data loading (scoped by role) and every derived metric.
import { MODULES, PASS_MARK, EXPIRY_WARNING_DAYS, NEW_WORKER_DAYS, CERT_PUBLIC_KEY_B64 } from './config.js';

const DAY = 864e5;

export const store = {
  backend: null,
  session: null, // { uid, name, email, photoURL, role, employer }
  data: { workers: [], attempts: [], certificates: [], refreshers: [] },
  questions: {}, // moduleId -> { qid: {prompt:{en,hi}, critical} }
  loadedAt: null,
  filters: JSON.parse(sessionStorage.getItem('johar-filters') ?? 'null') ?? { sector: '', employer: '', period: 90 },
  listeners: new Set(),

  get publicKey() { return this.backend?.publicKey ?? CERT_PUBLIC_KEY_B64; },
  get role() { return this.session?.role; },
  get isAdmin() { return this.role === 'admin'; },
  get canRevoke() { return this.role === 'admin' || this.role === 'inspector'; },
  /** Supervisors only ever see their own employer. */
  get scopeEmployer() { return this.role === 'supervisor' ? this.session.employer : null; },

  onChange(fn) { this.listeners.add(fn); return () => this.listeners.delete(fn); },
  emit() { this.listeners.forEach((fn) => fn()); },

  setFilter(key, value) {
    this.filters[key] = value;
    sessionStorage.setItem('johar-filters', JSON.stringify(this.filters));
    this._cache = null;
    this.emit();
  },

  async load() {
    const employer = this.scopeEmployer ?? undefined;
    const names = ['workers', 'attempts', 'certificates', 'refreshers'];
    const results = await Promise.all(names.map((n) => this.backend.list(n, { employer }).catch((e) => { console.warn(n, e); return []; })));
    names.forEach((n, i) => (this.data[n] = results[i]));
    this.loadedAt = new Date();
    this._cache = null;
    await this.loadQuestions();
    this.emit();
  },

  async loadQuestions() {
    await Promise.all(MODULES.map(async (m) => {
      if (this.questions[m.id]) return;
      this.questions[m.id] = {};
      try {
        const json = await (await fetch(`modules/${m.id}.json`)).json();
        for (const q of json.questions) this.questions[m.id][q.id] = { prompt: q.prompt, critical: !!q.critical, explanation: q.explanation };
      } catch { /* run sync_modules.sh to copy module files */ }
    }));
  },

  // ---------------- Lookups ----------------
  worker(id) { return this.data.workers.find((w) => w.id === id); },
  employers() { return [...new Set(this.data.workers.map((w) => w.employer).filter(Boolean))].sort(); },

  /** Latest certificate status for one worker + module. */
  certStatus(workerId, moduleId) {
    let best = null;
    for (const c of this.data.certificates) {
      if (c.workerId !== workerId || c.moduleId !== moduleId) continue;
      if (!best || c.expiresAt > best.expiresAt) best = c;
    }
    return { status: best ? certificateStatus(best) : 'none', cert: best };
  },

  // ---------------- Filtered views (memoised until data/filters change) ----------------
  view() {
    if (this._cache) return this._cache;
    const f = this.filters;
    const since = f.period ? Date.now() - f.period * DAY : 0;
    const workers = this.data.workers.filter((w) => (!f.sector || w.sector === f.sector) && (!f.employer || w.employer === f.employer));
    const ids = new Set(workers.map((w) => w.id));
    const attemptsAll = this.data.attempts.filter((a) => ids.has(a.workerId));
    const attempts = attemptsAll.filter((a) => Date.parse(a.completedAt) >= since);
    const certificates = this.data.certificates.filter((c) => ids.has(c.workerId));
    const refreshers = this.data.refreshers.filter((r) => ids.has(r.workerId) && Date.parse(r.takenAt) >= since);
    const rows = workers.map((w) => this.workerRow(w, attemptsAll));
    return (this._cache = { workers, rows, attempts, attemptsAll, certificates, refreshers, since });
  },

  workerRow(w, attemptsAll) {
    const statuses = {};
    for (const m of MODULES) statuses[m.id] = this.certStatus(w.id, m.id).status;
    const mine = attemptsAll.filter((a) => a.workerId === w.id);
    const last = mine.reduce((mx, a) => (a.completedAt > mx ? a.completedAt : mx), '');
    const daysIn = Math.floor((Date.now() - Date.parse(w.createdAt)) / DAY);
    const certified = MODULES.filter((m) => ['valid', 'expiring'].includes(statuses[m.id])).length;
    return {
      w, statuses, lastActivity: last || null, daysIn, certified,
      full: certified === MODULES.length,
      atRisk: daysIn <= NEW_WORKER_DAYS && certified === 0,
      expiring: MODULES.some((m) => statuses[m.id] === 'expiring'),
      expired: MODULES.some((m) => statuses[m.id] === 'expired'),
      attempts: mine.length,
    };
  },

  kpis() {
    const v = this.view();
    const n = v.rows.length;
    const passed = v.attempts.filter((a) => a.passed).length;
    const retention = avg(v.refreshers.map((r) => r.percent));
    return {
      workers: n,
      fullyCertified: n ? (v.rows.filter((r) => r.full).length / n) * 100 : null,
      passRate: v.attempts.length ? (passed / v.attempts.length) * 100 : null,
      attempts: v.attempts.length,
      expiring: v.certificates.filter((c) => certificateStatus(c) === 'expiring').length,
      atRisk: v.rows.filter((r) => r.atRisk).length,
      retention,
      retentionBase: avg(v.refreshers.map((r) => r.originalPercent)),
    };
  },

  /** Attempts and passes per week for the last `weeks` weeks. */
  weekly(weeks = 12) {
    const v = this.view();
    const start = startOfWeek(Date.now()) - (weeks - 1) * 7 * DAY;
    const labels = [], attempts = Array(weeks).fill(0), passes = Array(weeks).fill(0);
    for (let i = 0; i < weeks; i++) labels.push(new Date(start + i * 7 * DAY));
    for (const a of v.attemptsAll) {
      const i = Math.floor((Date.parse(a.completedAt) - start) / (7 * DAY));
      if (i < 0 || i >= weeks) continue;
      attempts[i]++;
      if (a.passed) passes[i]++;
    }
    return { labels, attempts, passes };
  },

  moduleStats() {
    const v = this.view();
    return MODULES.map((m) => {
      const list = v.attempts.filter((a) => a.moduleId === m.id);
      const firsts = new Map();
      for (const a of [...v.attemptsAll].sort((x, y) => x.completedAt.localeCompare(y.completedAt))) {
        if (a.moduleId === m.id && !firsts.has(a.workerId)) firsts.set(a.workerId, a);
      }
      const ref = v.refreshers.filter((r) => r.moduleId === m.id);
      return {
        m,
        attempts: list.length,
        passRate: list.length ? (list.filter((a) => a.passed).length / list.length) * 100 : null,
        firstTimePass: firsts.size ? ([...firsts.values()].filter((a) => a.passed).length / firsts.size) * 100 : null,
        avgQuiz: avg(list.map((a) => a.quizPercent)),
        avgAr: avg(list.map((a) => a.arPercent)),
        criticalFails: list.filter((a) => (a.criticalMissed ?? []).length).length,
        retention: avg(ref.map((r) => r.percent)),
        retentionBase: avg(ref.map((r) => r.originalPercent)),
        retentionN: ref.length,
        valid: v.certificates.filter((c) => c.moduleId === m.id && ['valid', 'expiring'].includes(certificateStatus(c))).length,
      };
    });
  },

  /** How often each question was answered wrong (in the period). */
  missedQuestions(moduleId) {
    const v = this.view();
    const list = v.attempts.filter((a) => !moduleId || a.moduleId === moduleId);
    const counts = {};
    for (const a of list) for (const q of a.wrongQuestionIds ?? []) {
      const key = `${a.moduleId}:${q}`;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return Object.entries(counts)
      .map(([key, n]) => {
        const [m, q] = key.split(':');
        const meta = this.questions[m]?.[q];
        const asked = list.filter((a) => a.moduleId === m).length;
        return { moduleId: m, qid: q, n, rate: asked ? (n / asked) * 100 : 0, prompt: meta?.prompt, critical: meta?.critical, explanation: meta?.explanation };
      })
      .sort((a, b) => b.n - a.n);
  },

  scoreHistogram(moduleId) {
    const buckets = Array(10).fill(0);
    for (const a of this.view().attempts) {
      if (moduleId && a.moduleId !== moduleId) continue;
      buckets[Math.min(9, Math.floor(a.totalPercent / 10))]++;
    }
    return buckets;
  },

  sectorStats() {
    const v = this.view();
    const out = {};
    for (const r of v.rows) {
      const s = (out[r.w.sector] ??= { workers: 0, full: 0, atRisk: 0 });
      s.workers++; if (r.full) s.full++; if (r.atRisk) s.atRisk++;
    }
    return out;
  },
};

export function certificateStatus(c) {
  if (c.status === 'revoked') return 'revoked';
  const now = Date.now() / 1000;
  if (c.expiresAt < now) return 'expired';
  if (c.expiresAt < now + EXPIRY_WARNING_DAYS * 86400) return 'expiring';
  return 'valid';
}
export const daysLeft = (c) => Math.ceil((c.expiresAt * 1000 - Date.now()) / DAY);
export const avg = (xs) => (xs.length ? xs.reduce((s, x) => s + x, 0) / xs.length : null);
export const passMark = PASS_MARK;
function startOfWeek(ts) {
  const d = new Date(ts);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - ((d.getDay() + 6) % 7)); // Monday
  return d.getTime();
}
