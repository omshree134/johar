import { store } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, avatar, pill, fmtDate, downloadCsv, empty } from '../ui.js';
import { MODULES } from '../config.js';
import { pageHead, moduleBadge, moduleTitle, loading } from './common.js';

const PAGE = 25;
let ui = { q: '', status: 'all', sort: 'name', page: 0 };

const FILTERS = {
  all: () => true,
  full: (r) => r.full,
  partial: (r) => r.certified > 0 && !r.full,
  none: (r) => r.certified === 0,
  risk: (r) => r.atRisk,
  expiring: (r) => r.expiring,
  expired: (r) => r.expired,
};
const SORTS = {
  name: (a, b) => a.w.name.localeCompare(b.w.name),
  newest: (a, b) => a.daysIn - b.daysIn,
  activity: (a, b) => (b.lastActivity ?? '').localeCompare(a.lastActivity ?? ''),
  least: (a, b) => a.certified - b.certified || a.w.name.localeCompare(b.w.name),
};

export function render(el, params) {
  if (loading(el)) return;
  if (params.status && FILTERS[params.status]) { ui = { ...ui, status: params.status, page: 0 }; history.replaceState(null, '', '#/workers'); }
  const rows = store.view().rows;
  const counts = Object.fromEntries(Object.keys(FILTERS).map((k) => [k, rows.filter(FILTERS[k]).length]));

  el.innerHTML = `
    ${pageHead(t('workersTitle'), t('workersSub'), `<button class="btn secondary" id="csv" type="button">${icon('download')}${esc(t('exportCsv'))}</button>`)}
    <div class="card">
      <div class="toolbar">
        <label class="search">${icon('search')}<input class="input" id="q" type="search" placeholder="${esc(t('searchWorkers'))}" value="${esc(ui.q)}" aria-label="${esc(t('searchWorkers'))}"></label>
        <select class="input" id="sort" aria-label="${esc(t('sortBy'))}">
          ${Object.keys(SORTS).map((k) => `<option value="${k}" ${ui.sort === k ? 'selected' : ''}>${esc(t('sort_' + k))}</option>`).join('')}
        </select>
      </div>
      <div class="chips" style="margin-bottom:14px">
        ${Object.keys(FILTERS).map((k) => `<button class="chip ${ui.status === k ? 'on' : ''}" data-status="${k}" type="button">${esc(t('wf_' + k))}<span class="count">${counts[k]}</span></button>`).join('')}
      </div>
      <div id="tableHost"></div>
    </div>`;

  const draw = () => {
    const q = ui.q.trim().toLowerCase();
    const list = rows.filter(FILTERS[ui.status])
      .filter((r) => !q || `${r.w.name} ${r.w.employeeId} ${r.w.employer}`.toLowerCase().includes(q))
      .sort(SORTS[ui.sort]);
    const pages = Math.max(1, Math.ceil(list.length / PAGE));
    ui.page = Math.min(ui.page, pages - 1);
    const slice = list.slice(ui.page * PAGE, ui.page * PAGE + PAGE);
    el.querySelector('#tableHost').innerHTML = list.length ? `
      <div class="table-wrap"><table class="table"><thead><tr>
        <th>${esc(t('name'))}</th><th>${esc(t('employer'))}</th>
        ${MODULES.map((m) => `<th title="${esc(moduleTitle(m.id))}"><span class="module-cell">${moduleBadge(m.id, 20)}${esc(moduleTitle(m.id).split(' ')[0])}</span></th>`).join('')}
        <th>${esc(t('joined'))}</th><th>${esc(t('lastActive'))}</th></tr></thead>
      <tbody>${slice.map((r) => `<tr class="link" data-id="${r.w.id}" tabindex="0">
        <td><div style="display:flex;gap:10px;align-items:center">${avatar(r.w.name)}<div><b>${esc(r.w.name)}</b>
          <div class="muted small nowrap">${esc(r.w.employeeId)}${r.atRisk ? ` · <span style="color:var(--red);font-weight:700">${esc(t('atRisk'))}</span>` : ''}</div></div></div></td>
        <td><div>${esc(r.w.employer)}</div><div class="muted small">${esc(t(r.w.sector))}</div></td>
        ${MODULES.map((m) => `<td>${pill(r.statuses[m.id])}</td>`).join('')}
        <td class="nowrap">${esc(fmtDate(r.w.createdAt))}<div class="muted small">${esc(t('daysIn', { n: r.daysIn }))}</div></td>
        <td class="nowrap muted">${esc(fmtDate(r.lastActivity))}</td></tr>`).join('')}</tbody></table></div>
      <div class="pager"><span class="muted small">${esc(t('showing', { from: ui.page * PAGE + 1, to: ui.page * PAGE + slice.length, total: list.length }))}</span>
        <div style="display:flex;gap:6px"><button class="btn outline sm" id="prev" ${ui.page === 0 ? 'disabled' : ''} type="button">${icon('back')}</button>
        <button class="btn outline sm" id="next" ${ui.page >= pages - 1 ? 'disabled' : ''} type="button">${icon('next')}</button></div></div>`
      : empty(t('noWorkersMatch'), 'search');

    el.querySelectorAll('tr[data-id]').forEach((tr) => {
      const open = () => (location.hash = `#/workers/${tr.dataset.id}`);
      tr.addEventListener('click', open);
      tr.addEventListener('keydown', (e) => e.key === 'Enter' && open());
    });
    el.querySelector('#prev')?.addEventListener('click', () => { ui.page--; draw(); });
    el.querySelector('#next')?.addEventListener('click', () => { ui.page++; draw(); });
    return list;
  };
  let current = draw();

  el.querySelector('#q').addEventListener('input', (e) => { ui.q = e.target.value; ui.page = 0; current = draw(); });
  el.querySelector('#sort').addEventListener('change', (e) => { ui.sort = e.target.value; current = draw(); });
  el.querySelectorAll('[data-status]').forEach((b) => b.addEventListener('click', () => {
    ui.status = b.dataset.status; ui.page = 0;
    el.querySelectorAll('[data-status]').forEach((x) => x.classList.toggle('on', x === b));
    current = draw();
  }));
  el.querySelector('#csv').addEventListener('click', () => downloadCsv(`johar-workers-${new Date().toISOString().slice(0, 10)}.csv`, [
    ['Name', 'Worker ID', 'Employer', 'Sector', 'Language', 'Registered', 'Days since joining', ...MODULES.map((m) => m.title.en), 'Last activity', 'At risk'],
    ...current.map((r) => [r.w.name, r.w.employeeId, r.w.employer, r.w.sector, r.w.language, r.w.createdAt?.slice(0, 10), r.daysIn,
      ...MODULES.map((m) => r.statuses[m.id]), r.lastActivity?.slice(0, 10) ?? '', r.atRisk ? 'yes' : 'no']),
  ]));
}
