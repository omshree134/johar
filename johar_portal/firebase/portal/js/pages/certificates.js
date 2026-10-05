import { store, certificateStatus, daysLeft } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, pill, fmtDate, pct, downloadCsv, empty } from '../ui.js';
import { MODULES } from '../config.js';
import { pageHead, moduleCell, moduleTitle, loading, shortId } from './common.js';
import { revokeFlow, reinstateFlow } from './cert-actions.js';

const PAGE = 30;
let ui = { status: 'all', module: '', q: '', page: 0 };

export function render(el, params) {
  if (loading(el)) return;
  if (params.status) { ui = { ...ui, status: params.status, page: 0 }; history.replaceState(null, '', '#/certificates'); }
  const all = store.view().certificates.map((c) => ({ c, s: certificateStatus(c), w: store.worker(c.workerId) }));
  const statuses = ['all', 'valid', 'expiring', 'expired', 'revoked'];
  const count = (s) => (s === 'all' ? all.length : all.filter((x) => x.s === s).length);

  el.innerHTML = `
    ${pageHead(t('certsTitle'), t('certsSub'), `<a class="btn secondary" href="#/verify">${icon('qr')}${esc(t('navVerify'))}</a>
      <button class="btn secondary" id="csv" type="button">${icon('download')}${esc(t('exportCsv'))}</button>`)}
    <div class="card">
      <div class="toolbar">
        <label class="search">${icon('search')}<input class="input" id="q" type="search" value="${esc(ui.q)}" placeholder="${esc(t('searchCerts'))}" aria-label="${esc(t('searchCerts'))}"></label>
        <select class="input" id="mod" aria-label="${esc(t('module'))}"><option value="">${esc(t('allModules'))}</option>
          ${MODULES.map((m) => `<option value="${m.id}" ${ui.module === m.id ? 'selected' : ''}>${esc(moduleTitle(m.id))}</option>`).join('')}</select>
      </div>
      <div class="chips" style="margin-bottom:14px">${statuses.map((s) => `<button class="chip ${ui.status === s ? 'on' : ''}" data-s="${s}" type="button">${esc(s === 'all' ? t('all') : t(s))}<span class="count">${count(s)}</span></button>`).join('')}</div>
      <div id="host"></div>
    </div>`;

  let list = [];
  const draw = () => {
    const q = ui.q.trim().toLowerCase();
    list = all.filter((x) => (ui.status === 'all' || x.s === ui.status) && (!ui.module || x.c.moduleId === ui.module))
      .filter((x) => !q || `${x.c.id} ${x.w?.name ?? ''} ${x.c.employeeId} ${x.c.employer}`.toLowerCase().includes(q))
      .sort((a, b) => (ui.status === 'expiring' ? a.c.expiresAt - b.c.expiresAt : b.c.issuedAt - a.c.issuedAt));
    const pages = Math.max(1, Math.ceil(list.length / PAGE));
    ui.page = Math.min(ui.page, pages - 1);
    const slice = list.slice(ui.page * PAGE, ui.page * PAGE + PAGE);
    el.querySelector('#host').innerHTML = list.length ? `<div class="table-wrap"><table class="table"><thead><tr>
      <th>${esc(t('certId'))}</th><th>${esc(t('name'))}</th><th>${esc(t('module'))}</th><th class="right">${esc(t('score'))}</th>
      <th>${esc(t('issued'))}</th><th>${esc(t('validUntil'))}</th><th>${esc(t('status'))}</th><th class="no-print"></th></tr></thead><tbody>
      ${slice.map(({ c, s, w }) => `<tr>
        <td class="num"><a href="#/certificates/${c.id}"><b>${esc(shortId(c.id))}</b></a></td>
        <td><a href="#/workers/${c.workerId}" style="color:inherit;text-decoration:none"><b>${esc(w?.name ?? '–')}</b></a><div class="muted small">${esc(c.employeeId)} · ${esc(c.employer)}</div></td>
        <td>${moduleCell(c.moduleId, 20)}</td><td class="right num">${pct(c.score)}</td>
        <td class="nowrap">${esc(fmtDate(c.issuedAt * 1000))}</td>
        <td class="nowrap">${esc(fmtDate(c.expiresAt * 1000))}${s === 'valid' || s === 'expiring' ? `<div class="muted small">${esc(t('daysLeft', { n: daysLeft(c) }))}</div>` : ''}</td>
        <td>${pill(s)}${c.revokedReason ? `<div class="muted small" style="max-width:180px">${esc(c.revokedReason)}</div>` : ''}</td>
        <td class="nowrap no-print"><a class="btn ghost sm" href="#/certificates/${c.id}">${icon('eye')}</a>
          ${store.canRevoke ? (s === 'revoked'
            ? `<button class="btn ghost sm" data-reinstate="${c.id}" type="button">${esc(t('reinstate'))}</button>`
            : `<button class="btn ghost sm" style="color:var(--red)" data-revoke="${c.id}" type="button">${esc(t('revoke'))}</button>`) : ''}</td></tr>`).join('')}
      </tbody></table></div>
      <div class="pager"><span class="muted small">${esc(t('showing', { from: ui.page * PAGE + 1, to: ui.page * PAGE + slice.length, total: list.length }))}</span>
        <div style="display:flex;gap:6px"><button class="btn outline sm" id="prev" ${ui.page === 0 ? 'disabled' : ''} type="button">${icon('back')}</button>
        <button class="btn outline sm" id="next" ${ui.page >= pages - 1 ? 'disabled' : ''} type="button">${icon('next')}</button></div></div>`
      : empty(t('noCertsMatch'), 'certificate');

    const byId = (id) => all.find((x) => x.c.id === id).c;
    el.querySelectorAll('[data-revoke]').forEach((b) => b.addEventListener('click', () => revokeFlow(byId(b.dataset.revoke))));
    el.querySelectorAll('[data-reinstate]').forEach((b) => b.addEventListener('click', () => reinstateFlow(byId(b.dataset.reinstate))));
    el.querySelector('#prev')?.addEventListener('click', () => { ui.page--; draw(); });
    el.querySelector('#next')?.addEventListener('click', () => { ui.page++; draw(); });
  };
  draw();

  el.querySelector('#q').addEventListener('input', (e) => { ui.q = e.target.value; ui.page = 0; draw(); });
  el.querySelector('#mod').addEventListener('change', (e) => { ui.module = e.target.value; ui.page = 0; draw(); });
  el.querySelectorAll('[data-s]').forEach((b) => b.addEventListener('click', () => {
    ui.status = b.dataset.s; ui.page = 0;
    el.querySelectorAll('[data-s]').forEach((x) => x.classList.toggle('on', x === b));
    draw();
  }));
  el.querySelector('#csv').addEventListener('click', () => downloadCsv(`johar-certificates-${new Date().toISOString().slice(0, 10)}.csv`, [
    ['Certificate ID', 'Worker', 'Worker ID', 'Employer', 'Sector', 'Module', 'Score', 'Issued', 'Expires', 'Status', 'Cancellation reason'],
    ...list.map(({ c, s, w }) => [c.id, w?.name ?? '', c.employeeId, c.employer, c.sector, MODULES.find((m) => m.id === c.moduleId)?.title.en ?? c.moduleId,
      c.score, new Date(c.issuedAt * 1000).toISOString().slice(0, 10), new Date(c.expiresAt * 1000).toISOString().slice(0, 10), s, c.revokedReason ?? '']),
  ]));
}
