import { store, certificateStatus, daysLeft, passMark } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, avatar, pill, fmtDate, fmtDateTime, pct, empty, lineChart } from '../ui.js';
import { MODULES, NEW_WORKER_DAYS } from '../config.js';
import { pageHead, crumb, moduleBadge, moduleTitle, moduleCell, qText, loading, shortId } from './common.js';

export function render(el, { id }) {
  if (loading(el)) return;
  const w = store.worker(id);
  if (!w) { el.innerHTML = `${crumb('#/workers', t('navWorkers'))}${empty(t('notFoundWorker'), 'user')}`; return; }

  const row = store.workerRow(w, store.data.attempts);
  const attempts = store.data.attempts.filter((a) => a.workerId === id).sort((a, b) => b.completedAt.localeCompare(a.completedAt));
  const certs = store.data.certificates.filter((c) => c.workerId === id).sort((a, b) => b.issuedAt - a.issuedAt);
  const refs = store.data.refreshers.filter((r) => r.workerId === id).sort((a, b) => b.takenAt.localeCompare(a.takenAt));
  const langName = { en: 'English', hi: 'हिन्दी', sat: 'ᱥᱟᱱᱛᱟᱲᱤ' }[w.language] ?? w.language;
  const chronological = [...attempts].reverse();

  el.innerHTML = `
    ${pageHead(w.name, `${w.employeeId} · ${w.employer}`, '', crumb('#/workers', t('navWorkers')))}
    <div class="card">
      <div class="profile-head">${avatar(w.name, null, 'lg')}
        <div class="grow"><h2 style="font-size:22px">${esc(w.name)}</h2>
          <div class="muted">${esc(t(w.sector))} · ${esc(w.employer)}</div>
          <div style="display:flex;gap:6px;margin-top:8px;flex-wrap:wrap">
            ${row.full ? pill('valid', t('fullyCertified')) : ''}
            ${row.atRisk ? pill('risk', t('atRiskLong', { days: NEW_WORKER_DAYS })) : ''}
            ${row.expiring ? pill('expiring', t('hasExpiring')) : ''}
          </div></div>
      </div>
      <dl class="facts">
        <div><dt>${esc(t('workerId'))}</dt><dd>${esc(w.employeeId)}</dd></div>
        <div><dt>${esc(t('joined'))}</dt><dd>${esc(fmtDate(w.createdAt))}</dd></div>
        <div><dt>${esc(t('daysSince'))}</dt><dd class="num">${row.daysIn}</dd></div>
        <div><dt>${esc(t('appLanguage'))}</dt><dd>${esc(langName)}</dd></div>
        <div><dt>${esc(t('attemptsH'))}</dt><dd class="num">${attempts.length}</dd></div>
        <div><dt>${esc(t('lastActive'))}</dt><dd>${esc(fmtDate(row.lastActivity))}</dd></div>
      </dl>
    </div>

    <section class="grid cols-3 mt">
      ${MODULES.map((m) => {
        const { status, cert } = store.certStatus(id, m.id);
        const last = attempts.find((a) => a.moduleId === m.id);
        return `<div class="card module-card">
          <div class="top">${moduleBadge(m.id, 40)}<div style="flex:1"><b>${esc(moduleTitle(m.id))}</b><div>${pill(status)}</div></div></div>
          <dl class="kv" style="margin:0">
            <dt>${esc(t('lastScore'))}</dt><dd>${last ? `${pct(last.totalPercent)} ${last.passed ? '' : `<span class="muted small">(${esc(t('notPassed'))})</span>`}` : '–'}</dd>
            <dt>${esc(t('validUntil'))}</dt><dd>${cert ? `${esc(fmtDate(cert.expiresAt * 1000))}${status === 'valid' || status === 'expiring' ? ` <span class="muted small">(${esc(t('daysLeft', { n: daysLeft(cert) }))})</span>` : ''}` : '–'}</dd>
          </dl>
          ${cert ? `<a class="btn secondary sm" href="#/certificates/${cert.id}">${icon('certificate')}${esc(t('viewCertificate'))}</a>` : ''}
        </div>`;
      }).join('')}
    </section>

    <section class="grid cols-2 mt">
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('scoreHistory'))}</h2><p>${esc(t('scoreHistoryHint', { mark: passMark }))}</p></div></div>
        ${chronological.length > 1 ? lineChart({
          labels: chronological.map((a) => fmtDate(a.completedAt)),
          series: [{ name: t('totalScore'), color: 'var(--manganese)', values: chronological.map((a) => Math.round(a.totalPercent)) }],
          yMax: 100, height: 200,
        }) : `<p class="muted">${esc(t('notEnoughData'))}</p>`}
      </div>
      <div class="card">
        <div class="card-head"><div class="grow"><h2>${esc(t('memoryChecks'))}</h2><p>${esc(t('memoryChecksHint'))}</p></div></div>
        ${refs.length ? `<ul class="list">${refs.map((r) => `<li>${moduleBadge(r.moduleId, 26)}
          <div class="grow"><b>${esc(moduleTitle(r.moduleId))}</b><div class="muted small">${esc(fmtDate(r.takenAt))} · ${esc(t('daysAfter', { n: r.daysAfter }))}</div></div>
          <span class="muted small num">${pct(r.originalPercent)} →</span>${pill(r.percent >= passMark ? 'passed' : 'failed', pct(r.percent))}</li>`).join('')}</ul>`
          : `<p class="muted">${esc(t('noRefreshersWorker'))}</p>`}
      </div>
    </section>

    <section class="card mt">
      <div class="card-head"><div class="grow"><h2>${esc(t('attemptHistory'))}</h2><p>${esc(t('attemptHistoryHint'))}</p></div></div>
      ${attempts.length ? `<div class="table-wrap"><table class="table"><thead><tr>
        <th>${esc(t('date'))}</th><th>${esc(t('module'))}</th><th class="right">${esc(t('test'))}</th><th class="right">${esc(t('arPractice'))}</th>
        <th class="right">${esc(t('total'))}</th><th>${esc(t('result'))}</th><th>${esc(t('lifeSafety'))}</th><th class="right">${esc(t('duration'))}</th><th>${esc(t('arMode'))}</th></tr></thead>
        <tbody>${attempts.map((a) => `<tr>
          <td class="nowrap">${esc(fmtDateTime(a.completedAt))}</td><td>${moduleCell(a.moduleId, 20)}</td>
          <td class="right num">${pct(a.quizPercent)}</td><td class="right num">${pct(a.arPercent)}</td><td class="right num"><b>${pct(a.totalPercent)}</b></td>
          <td>${pill(a.passed ? 'passed' : 'failed')}</td>
          <td>${(a.criticalMissed ?? []).length ? `<span style="color:var(--red);font-weight:700" title="${esc((a.criticalMissed ?? []).map((q) => qText(store.questions[a.moduleId]?.[q]?.prompt) || q).join('\n'))}">${esc(t('missedN', { n: a.criticalMissed.length }))}</span>` : `<span class="muted">${esc(t('allCorrect'))}</span>`}</td>
          <td class="right num nowrap">${a.durationSec ? `${Math.round(a.durationSec / 60)} min` : '–'}</td>
          <td class="muted small">${esc(t('mode_' + (a.arMode ?? 'orientation')))}</td></tr>`).join('')}</tbody></table></div>`
        : empty(t('noAttempts'))}
    </section>

    ${certs.length ? `<section class="card mt"><div class="card-head"><div class="grow"><h2>${esc(t('certificates'))}</h2></div></div>
      <div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('certId'))}</th><th>${esc(t('module'))}</th><th class="right">${esc(t('score'))}</th>
        <th>${esc(t('issued'))}</th><th>${esc(t('validUntil'))}</th><th>${esc(t('status'))}</th></tr></thead>
      <tbody>${certs.map((c) => `<tr class="link" data-href="#/certificates/${c.id}"><td class="num"><b>${esc(shortId(c.id))}</b></td><td>${moduleCell(c.moduleId, 20)}</td>
        <td class="right num">${pct(c.score)}</td><td class="nowrap">${esc(fmtDate(c.issuedAt * 1000))}</td><td class="nowrap">${esc(fmtDate(c.expiresAt * 1000))}</td>
        <td>${pill(certificateStatus(c))}</td></tr>`).join('')}</tbody></table></div></section>` : ''}`;

  el.querySelectorAll('[data-href]').forEach((tr) => tr.addEventListener('click', () => (location.hash = tr.dataset.href)));
}
