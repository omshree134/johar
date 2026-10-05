// Printable compliance report (for DGMS / Factories inspections) + raw data exports.
import { store, certificateStatus, daysLeft } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, pct, fmtDate, fmtDateTime, downloadCsv, logo } from '../ui.js';
import { MODULES, NEW_WORKER_DAYS } from '../config.js';
import { pageHead, moduleCell, moduleTitle, loading, periodLabel, qText } from './common.js';

const stamp = () => new Date().toISOString().slice(0, 10);

export function render(el) {
  if (loading(el)) return;
  const v = store.view();
  const k = store.kpis();
  const mods = store.moduleStats();
  const f = store.filters;
  const scope = store.scopeEmployer ?? f.employer ?? '';
  const scopeText = [scope || t('allEmployers'), f.sector ? t(f.sector) : t('allSectors')].join(' · ');
  const nonCompliant = v.rows.filter((r) => !r.full).sort((a, b) => a.certified - b.certified || a.w.name.localeCompare(b.w.name));
  const expiring = v.certificates.filter((c) => certificateStatus(c) === 'expiring').sort((a, b) => a.expiresAt - b.expiresAt);
  const partial = v.rows.filter((r) => r.certified > 0 && !r.full).length;
  const none = v.rows.filter((r) => r.certified === 0).length;
  const topMissed = store.missedQuestions().slice(0, 5);

  el.innerHTML = `
    ${pageHead(t('reportsTitle'), t('reportsSub'), `<button class="btn" id="print" type="button">${icon('print')}${esc(t('printReport'))}</button>`)}
    <div class="card no-print" style="margin-bottom:16px">
      <div class="card-head"><div class="grow"><h2>${esc(t('exportsTitle'))}</h2><p>${esc(t('exportsHint'))}</p></div></div>
      <div style="display:flex;gap:8px;flex-wrap:wrap">
        <button class="btn secondary" data-x="workers" type="button">${icon('download')}${esc(t('navWorkers'))}</button>
        <button class="btn secondary" data-x="attempts" type="button">${icon('download')}${esc(t('attemptsH'))}</button>
        <button class="btn secondary" data-x="certificates" type="button">${icon('download')}${esc(t('certificates'))}</button>
        <button class="btn secondary" data-x="refreshers" type="button">${icon('download')}${esc(t('memoryChecks'))}</button>
        <button class="btn secondary" data-x="noncompliant" type="button">${icon('download')}${esc(t('nonCompliant'))}</button>
      </div>
      <p class="small muted" style="margin:10px 0 0">${esc(t('exportsScope'))}: ${esc(scopeText)} · ${esc(periodLabel())}</p>
    </div>

    <article class="report" id="report">
      <div style="display:flex;gap:14px;align-items:center;margin-bottom:18px">
        <span style="background:var(--manganese);border-radius:14px;width:48px;height:48px;display:grid;place-items:center;flex:none">${logo(28)}</span>
        <div style="flex:1"><h1>${esc(t('reportHeading'))}</h1><div class="muted">${esc(scopeText)}</div></div>
        <div class="small muted" style="text-align:right">${esc(t('period'))}: ${esc(periodLabel())}<br>${esc(t('generated'))}: ${esc(fmtDateTime(new Date()))}<br>${esc(t('by'))}: ${esc(store.session.name)}</div>
      </div>

      <h2 style="margin:18px 0 8px">1. ${esc(t('summary'))}</h2>
      <div class="table-wrap"><table class="table"><tbody>
        <tr><td>${esc(t('kWorkers'))}</td><td class="right num"><b>${v.rows.length}</b></td></tr>
        <tr><td>${esc(t('rFull'))}</td><td class="right num"><b>${v.rows.length - partial - none}</b> (${pct(k.fullyCertified)})</td></tr>
        <tr><td>${esc(t('rPartial'))}</td><td class="right num">${partial}</td></tr>
        <tr><td>${esc(t('rNone'))}</td><td class="right num">${none}</td></tr>
        <tr><td>${esc(t('kRisk'))} (${esc(t('nRisk', { days: NEW_WORKER_DAYS }))})</td><td class="right num"><b style="color:${k.atRisk ? 'var(--red)' : 'inherit'}">${k.atRisk}</b></td></tr>
        <tr><td>${esc(t('kPass'))}</td><td class="right num">${pct(k.passRate)} (${k.attempts} ${esc(t('attempts'))})</td></tr>
        <tr><td>${esc(t('kRetention'))}</td><td class="right num">${pct(k.retention)}${k.retentionBase != null ? ` (${esc(t('afterTraining'))}: ${pct(k.retentionBase)})` : ''}</td></tr>
        <tr><td>${esc(t('kExpiring'))}</td><td class="right num">${k.expiring}</td></tr>
      </tbody></table></div>

      <h2 style="margin:22px 0 8px">2. ${esc(t('byModuleTitle'))}</h2>
      <div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('module'))}</th><th class="right">${esc(t('validCerts'))}</th>
        <th class="right">${esc(t('attemptsH'))}</th><th class="right">${esc(t('kPass'))}</th><th class="right">${esc(t('firstTime'))}</th>
        <th class="right">${esc(t('test'))}</th><th class="right">${esc(t('arPractice'))}</th><th class="right">${esc(t('after7'))}</th></tr></thead><tbody>
        ${mods.map((s) => `<tr><td>${moduleCell(s.m.id, 20)}</td><td class="right num">${s.valid}</td><td class="right num">${s.attempts}</td>
          <td class="right num">${pct(s.passRate)}</td><td class="right num">${pct(s.firstTimePass)}</td><td class="right num">${pct(s.avgQuiz)}</td>
          <td class="right num">${pct(s.avgAr)}</td><td class="right num">${pct(s.retention)}</td></tr>`).join('')}
      </tbody></table></div>

      <h2 style="margin:22px 0 8px">3. ${esc(t('nonCompliant'))} (${nonCompliant.length})</h2>
      ${nonCompliant.length ? `<div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('name'))}</th><th>${esc(t('workerId'))}</th>
        <th>${esc(t('employer'))}</th><th class="right">${esc(t('daysSince'))}</th><th>${esc(t('missingTraining'))}</th></tr></thead><tbody>
        ${nonCompliant.map((r) => `<tr><td><b>${esc(r.w.name)}</b>${r.atRisk ? ` <span style="color:var(--red);font-weight:700">●</span>` : ''}</td>
          <td class="nowrap">${esc(r.w.employeeId)}</td><td>${esc(r.w.employer)}</td><td class="right num">${r.daysIn}</td>
          <td>${MODULES.filter((m) => !['valid', 'expiring'].includes(r.statuses[m.id])).map((m) => esc(moduleTitle(m.id))).join(', ')}</td></tr>`).join('')}
      </tbody></table></div><p class="small muted">● ${esc(t('riskLegend', { days: NEW_WORKER_DAYS }))}</p>` : `<p class="muted">${esc(t('allCompliant'))}</p>`}

      <h2 style="margin:22px 0 8px">4. ${esc(t('expiringTitle'))} (${expiring.length})</h2>
      ${expiring.length ? `<div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('name'))}</th><th>${esc(t('module'))}</th>
        <th>${esc(t('validUntil'))}</th><th class="right">${esc(t('daysLeftCol'))}</th></tr></thead><tbody>
        ${expiring.map((c) => `<tr><td>${esc(store.worker(c.workerId)?.name ?? c.employeeId)}</td><td>${esc(moduleTitle(c.moduleId))}</td>
          <td>${esc(fmtDate(c.expiresAt * 1000))}</td><td class="right num">${daysLeft(c)}</td></tr>`).join('')}
      </tbody></table></div>` : `<p class="muted">${esc(t('noneExpiring'))}</p>`}

      <h2 style="margin:22px 0 8px">5. ${esc(t('missedTitle'))}</h2>
      ${topMissed.length ? `<ol>${topMissed.map((q) => `<li style="margin:6px 0">${esc(qText(q.prompt) || q.qid)} <span class="muted small">(${esc(moduleTitle(q.moduleId))}, ${q.n}×)</span></li>`).join('')}</ol>` : `<p class="muted">${esc(t('noData'))}</p>`}

      <div class="sig"><div>${esc(t('preparedBy'))}</div><div>${esc(t('safetyOfficer'))}</div></div>
    </article>`;

  el.querySelector('#print').addEventListener('click', () => window.print());
  const W = (id) => store.worker(id);
  const exporters = {
    workers: () => [['Name', 'Worker ID', 'Employer', 'Sector', 'Registered', ...MODULES.map((m) => m.title.en)],
      ...v.rows.map((r) => [r.w.name, r.w.employeeId, r.w.employer, r.w.sector, r.w.createdAt?.slice(0, 10), ...MODULES.map((m) => r.statuses[m.id])])],
    attempts: () => [['Date', 'Worker', 'Worker ID', 'Employer', 'Module', 'Test %', 'AR %', 'Total %', 'Passed', 'Life-safety missed', 'Minutes', 'AR mode'],
      ...v.attempts.map((a) => [a.completedAt, W(a.workerId)?.name, W(a.workerId)?.employeeId, W(a.workerId)?.employer, a.moduleId,
        Math.round(a.quizPercent), Math.round(a.arPercent), Math.round(a.totalPercent), a.passed ? 'yes' : 'no', (a.criticalMissed ?? []).join(' '),
        a.durationSec ? Math.round(a.durationSec / 60) : '', a.arMode])],
    certificates: () => [['Certificate ID', 'Worker', 'Worker ID', 'Employer', 'Module', 'Score', 'Issued', 'Expires', 'Status', 'Reason'],
      ...v.certificates.map((c) => [c.id, W(c.workerId)?.name, c.employeeId, c.employer, c.moduleId, c.score,
        new Date(c.issuedAt * 1000).toISOString().slice(0, 10), new Date(c.expiresAt * 1000).toISOString().slice(0, 10), certificateStatus(c), c.revokedReason ?? ''])],
    refreshers: () => [['Date', 'Worker', 'Worker ID', 'Module', 'Days after training', 'Score after training %', 'Score now %'],
      ...v.refreshers.map((r) => [r.takenAt, W(r.workerId)?.name, W(r.workerId)?.employeeId, r.moduleId, r.daysAfter, Math.round(r.originalPercent), Math.round(r.percent)])],
    noncompliant: () => [['Name', 'Worker ID', 'Employer', 'Days since joining', 'At risk', 'Missing training'],
      ...nonCompliant.map((r) => [r.w.name, r.w.employeeId, r.w.employer, r.daysIn, r.atRisk ? 'yes' : 'no',
        MODULES.filter((m) => !['valid', 'expiring'].includes(r.statuses[m.id])).map((m) => m.title.en).join('; ')])],
  };
  el.querySelectorAll('[data-x]').forEach((b) => b.addEventListener('click', () => downloadCsv(`johar-${b.dataset.x}-${stamp()}.csv`, exporters[b.dataset.x]())));
}
