import { store, passMark } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, pct, fmtNum, barRows, lineChart, donut, colorFor, fmtDate, avatar, pill } from '../ui.js';
import { MODULES, NEW_WORKER_DAYS } from '../config.js';
import { pageHead, moduleBadge, moduleTitle, qText, loading, periodLabel } from './common.js';
import { certificateStatus, daysLeft } from '../store.js';

export function render(el) {
  if (loading(el)) return;
  const k = store.kpis();
  const v = store.view();
  const kpi = (href, ic, label, value, note, cls = '') =>
    `<a class="card kpi ${cls}" href="${href}"><span class="ico">${icon(ic)}</span><span class="label">${esc(label)}</span>
      <span class="value num">${esc(value)}</span><span class="note">${esc(note)}</span></a>`;

  // Weekly activity
  const wk = store.weekly(12);
  const weekLabels = wk.labels.map((d) => d.toLocaleDateString(undefined, { day: 'numeric', month: 'short' }));

  // Certificate status distribution
  const counts = { valid: 0, expiring: 0, expired: 0, revoked: 0 };
  for (const c of v.certificates) counts[certificateStatus(c)]++;

  const mods = store.moduleStats();
  const atRisk = v.rows.filter((r) => r.atRisk).sort((a, b) => a.daysIn - b.daysIn);
  const expiring = v.certificates.filter((c) => certificateStatus(c) === 'expiring').sort((a, b) => a.expiresAt - b.expiresAt);
  const missed = store.missedQuestions().slice(0, 5);
  const sectors = store.sectorStats();

  el.innerHTML = `
    ${pageHead(t('overviewTitle'), `${t('overviewSub')} · ${periodLabel()}`)}
    <section class="grid kpis">
      ${kpi('#/workers', 'workers', t('kWorkers'), fmtNum(k.workers), t('nWorkers'))}
      ${kpi('#/workers?status=full', 'certificate', t('kCertified'), pct(k.fullyCertified), t('nCertified'), 'good')}
      ${kpi('#/insights', 'check', t('kPass'), pct(k.passRate), `${fmtNum(k.attempts)} ${t('attempts')}`)}
      ${kpi('#/certificates?status=expiring', 'clock', t('kExpiring'), fmtNum(k.expiring), t('nExpiring'), k.expiring ? 'warn' : '')}
      ${kpi('#/workers?status=risk', 'alert', t('kRisk'), fmtNum(k.atRisk), t('nRisk', { days: NEW_WORKER_DAYS }), k.atRisk ? 'alert' : 'good')}
      ${kpi('#/insights', 'brain', t('kRetention'), pct(k.retention), k.retentionBase != null ? t('nRetention', { base: pct(k.retentionBase) }) : t('noData'), k.retention != null && k.retention >= passMark ? 'good' : '')}
    </section>

    <section class="grid cols-2 mt">
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('activityTitle'))}</h2><p>${esc(t('activityHint'))}</p></div></div>
        ${lineChart({ labels: weekLabels, series: [
          { name: t('attempts'), color: 'var(--manganese)', values: wk.attempts },
          { name: t('passes'), color: 'var(--green)', values: wk.passes },
        ] })}
      </div>
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('certStatusTitle'))}</h2><p>${esc(t('certStatusHint'))}</p></div>
          <a class="btn ghost sm" href="#/certificates">${esc(t('viewAll'))}</a></div>
        ${donut([
          { label: t('valid'), value: counts.valid, color: 'var(--green)' },
          { label: t('expiring'), value: counts.expiring, color: 'var(--yellow)' },
          { label: t('expired'), value: counts.expired, color: 'var(--red)' },
          { label: t('revoked'), value: counts.revoked, color: '#7A1414' },
        ], fmtNum(v.certificates.length), t('certificates'))}
      </div>
    </section>

    <section class="grid cols-2 mt">
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('byModuleTitle'))}</h2><p>${esc(t('byModuleHint', { mark: passMark }))}</p></div></div>
        ${barRows(mods.map((s) => ({
          label: `<span class="module-cell">${moduleBadge(s.m.id, 22)}${esc(moduleTitle(s.m.id))}</span>`,
          sub: `${fmtNum(s.attempts)} ${t('attempts')} · ${t('firstTime')} ${pct(s.firstTimePass)}`,
          value: s.passRate ?? 0, text: pct(s.passRate), color: colorFor(s.passRate ?? 0, passMark),
        })), { mark: passMark })}
      </div>
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('retentionTitle'))}</h2><p>${esc(t('retentionHint'))}</p></div></div>
        ${mods.some((s) => s.retentionN) ? mods.filter((s) => s.retentionN).map((s) => `
          <div style="margin-bottom:6px"><span class="module-cell">${moduleBadge(s.m.id, 20)}<b>${esc(moduleTitle(s.m.id))}</b></span> <span class="muted small">(${s.retentionN} ${esc(t('checks'))})</span></div>
          ${barRows([
            { label: esc(t('afterTraining')), value: s.retentionBase, color: 'var(--manganese)' },
            { label: esc(t('after7')), value: s.retention, color: colorFor(s.retention, passMark) },
          ], { mark: passMark })}`).join('') : `<p class="muted">${esc(t('noRefreshers'))}</p>`}
      </div>
    </section>

    <section class="grid cols-3 mt">
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('riskTitle'))}</h2><p>${esc(t('riskHint', { days: NEW_WORKER_DAYS }))}</p></div>
          ${atRisk.length ? `<a class="btn ghost sm" href="#/workers?status=risk">${esc(t('viewAll'))}</a>` : ''}</div>
        <ul class="list">${atRisk.slice(0, 6).map((r) => `<li class="link" data-href="#/workers/${r.w.id}">${avatar(r.w.name)}
          <div class="grow"><b>${esc(r.w.name)}</b><div class="muted small">${esc(r.w.employeeId)} · ${esc(r.w.employer)}</div></div>
          ${pill('risk', t('daysIn', { n: r.daysIn }))}</li>`).join('') || `<li class="muted">${esc(t('noneAtRisk'))}</li>`}</ul>
      </div>
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('expiringTitle'))}</h2><p>${esc(t('expiringHint'))}</p></div></div>
        <ul class="list">${expiring.slice(0, 6).map((c) => {
          const w = store.worker(c.workerId);
          return `<li class="link" data-href="#/workers/${c.workerId}">${moduleBadge(c.moduleId, 28)}
            <div class="grow"><b>${esc(w?.name ?? c.employeeId)}</b><div class="muted small">${esc(moduleTitle(c.moduleId))} · ${esc(fmtDate(c.expiresAt * 1000))}</div></div>
            ${pill('expiring', t('daysLeft', { n: daysLeft(c) }))}</li>`;
        }).join('') || `<li class="muted">${esc(t('noneExpiring'))}</li>`}</ul>
      </div>
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('missedTitle'))}</h2><p>${esc(t('missedHint'))}</p></div>
          <a class="btn ghost sm" href="#/insights">${esc(t('viewAll'))}</a></div>
        <ul class="list">${missed.map((q) => `<li>${`<span class="count-badge num">${q.n}</span>`}
          <div class="grow">${esc(qText(q.prompt) || q.qid)}<div class="muted small">${esc(moduleTitle(q.moduleId))}${q.critical ? ` · <b style="color:var(--red)">${esc(t('critical'))}</b>` : ''}</div></div></li>`).join('') || `<li class="muted">${esc(t('noData'))}</li>`}</ul>
      </div>
    </section>

    <section class="card mt">
      <div class="card-head"><div class="grow"><h2>${esc(t('sectorTitle'))}</h2><p>${esc(t('sectorHint'))}</p></div></div>
      <div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('sector'))}</th><th class="right">${esc(t('kWorkers'))}</th>
        <th>${esc(t('kCertified'))}</th><th class="right">${esc(t('kRisk'))}</th></tr></thead><tbody>
        ${Object.entries(sectors).map(([s, x]) => `<tr><td><b>${esc(t(s))}</b></td><td class="right num">${x.workers}</td>
          <td style="min-width:220px">${barRows([{ label: '', value: (x.full / x.workers) * 100, color: colorFor((x.full / x.workers) * 100, passMark) }])}</td>
          <td class="right num">${x.atRisk ? `<b style="color:var(--red)">${x.atRisk}</b>` : 0}</td></tr>`).join('') || `<tr><td colspan="4" class="muted">${esc(t('noData'))}</td></tr>`}
      </tbody></table></div>
    </section>`;

  el.querySelectorAll('[data-href]').forEach((li) => li.addEventListener('click', () => (location.hash = li.dataset.href)));
}
