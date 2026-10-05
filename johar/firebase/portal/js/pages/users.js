// Admin only: approve access requests, manage roles, read the audit log.
import { store } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, avatar, pill, fmtDate, fmtDateTime, modal, toast, empty } from '../ui.js';
import { pageHead } from './common.js';

let tab = 'requests';

export async function render(el) {
  el.innerHTML = `${pageHead(t('usersTitle'), t('usersSub'))}<div class="card empty">${esc(t('loading'))}</div>`;
  let users = [], audit = [];
  try {
    [users, audit] = await Promise.all([store.backend.listPortalUsers(), store.backend.listAudit(100)]);
  } catch (e) {
    el.innerHTML = `${pageHead(t('usersTitle'), t('usersSub'))}<div class="card">${esc(e.message)}</div>`;
    return;
  }
  const pending = users.filter((u) => u.status === 'pending');
  const others = users.filter((u) => u.status !== 'pending').sort((a, b) => (a.name ?? '').localeCompare(b.name ?? ''));
  const tabs = [['requests', t('tabRequests'), pending.length], ['users', t('tabUsers'), others.length], ['audit', t('tabAudit'), audit.length]];

  el.innerHTML = `${pageHead(t('usersTitle'), t('usersSub'))}
    <div class="chips" style="margin-bottom:16px">${tabs.map(([k, l, n]) => `<button class="chip ${tab === k ? 'on' : ''}" data-tab="${k}" type="button">${esc(l)}<span class="count">${n}</span></button>`).join('')}</div>
    <div class="card" id="body"></div>`;
  const body = el.querySelector('#body');

  if (tab === 'requests') {
    body.innerHTML = pending.length ? `<ul class="list">${pending.map((u) => `<li style="align-items:flex-start">
      ${avatar(u.name, u.photoURL)}
      <div class="grow"><b>${esc(u.name)}</b> <span class="muted small">${esc(u.email)}</span>
        <div style="margin:4px 0">${pill(u.requestedRole ?? 'supervisor', t('wants', { role: t('role_' + (u.requestedRole ?? 'supervisor')) }))}
          ${u.requestedEmployer ? `<span class="small"> · ${esc(u.requestedEmployer)}</span>` : ''}</div>
        <div class="muted small">${esc(u.organisation ?? '')}${u.phone ? ` · ${esc(u.phone)}` : ''} · ${esc(t('requested'))} ${esc(fmtDateTime(u.createdAt))}</div>
        ${u.note ? `<div class="small" style="margin-top:4px">“${esc(u.note)}”</div>` : ''}</div>
      <div style="display:flex;gap:6px;flex-wrap:wrap"><button class="btn success sm" data-approve="${u.id}" type="button">${icon('check')}${esc(t('approve'))}</button>
        <button class="btn outline sm" data-deny="${u.id}" type="button">${esc(t('deny'))}</button></div></li>`).join('')}</ul>`
      : empty(t('noRequests'), 'inbox');
  } else if (tab === 'users') {
    body.innerHTML = others.length ? `<div class="table-wrap"><table class="table"><thead><tr><th>${esc(t('name'))}</th><th>${esc(t('role'))}</th>
      <th>${esc(t('scope'))}</th><th>${esc(t('status'))}</th><th>${esc(t('lastLogin'))}</th><th></th></tr></thead><tbody>
      ${others.map((u) => `<tr><td><div style="display:flex;gap:10px;align-items:center">${avatar(u.name, u.photoURL)}<div><b>${esc(u.name)}</b><div class="muted small">${esc(u.email)}</div></div></div></td>
        <td>${u.role && u.role !== 'none' ? pill(u.role, t('role_' + u.role)) : '–'}</td>
        <td>${u.role === 'supervisor' ? esc(u.employer ?? '–') : `<span class="muted">${esc(t('allEmployers'))}</span>`}</td>
        <td>${pill(u.status === 'active' ? 'active' : 'disabled', t('ustatus_' + u.status))}</td>
        <td class="nowrap muted">${esc(fmtDate(u.lastLoginAt))}</td>
        <td class="nowrap">${u.id === store.session.uid ? `<span class="muted small">${esc(t('you'))}</span>` : `
          <button class="btn ghost sm" data-edit="${u.id}" type="button">${esc(t('edit'))}</button>
          <button class="btn ghost sm" data-toggle="${u.id}" type="button">${esc(u.status === 'active' ? t('disable') : t('enable'))}</button>
          <button class="btn ghost sm" style="color:var(--red)" data-remove="${u.id}" type="button">${esc(t('remove'))}</button>`}</td></tr>`).join('')}
      </tbody></table></div>` : empty(t('noUsers'), 'workers');
  } else {
    body.innerHTML = audit.length ? `<ul class="list">${audit.map((a) => `<li>
      <span class="avatar" style="background:var(--manganese-soft);color:var(--manganese)">${icon(a.action?.includes('Certificate') ? 'certificate' : 'shield')}</span>
      <div class="grow"><b>${esc(t('audit_' + a.action))}</b> · ${esc(a.targetLabel ?? '')}${a.details ? `<div class="muted small">${esc(a.details)}</div>` : ''}</div>
      <div class="small muted" style="text-align:right">${esc(a.byName ?? '')}<br>${esc(fmtDateTime(a.at))}</div></li>`).join('')}</ul>`
      : empty(t('noAudit'), 'list');
  }

  const find = (id) => users.find((u) => u.id === id);
  const log = (action, u, details = '') => store.backend.audit({ action, target: u.id, targetLabel: u.name, by: store.session.uid, byName: store.session.name, details });

  el.querySelectorAll('[data-tab]').forEach((b) => b.addEventListener('click', () => { tab = b.dataset.tab; render(el); }));
  el.querySelectorAll('[data-approve]').forEach((b) => b.addEventListener('click', async () => {
    const u = find(b.dataset.approve);
    const res = await roleDialog(t('approveTitle', { name: u.name }), u.requestedRole ?? 'supervisor', u.requestedEmployer ?? '');
    if (!res) return;
    await store.backend.updatePortalUser(u.id, { status: 'active', role: res.role, employer: res.role === 'supervisor' ? res.employer : null, approvedBy: store.session.uid });
    log('approveUser', u, `${res.role}${res.role === 'supervisor' ? ` · ${res.employer}` : ''}`);
    toast(t('approvedOk'), 'ok');
    render(el);
  }));
  el.querySelectorAll('[data-deny]').forEach((b) => b.addEventListener('click', async () => {
    const u = find(b.dataset.deny);
    const ok = await modal({ title: t('denyTitle', { name: u.name }), body: `<p class="muted">${esc(t('denyHint'))}</p>`,
      actions: [{ label: t('cancel'), value: false, cls: 'outline' }, { label: t('deny'), value: true, cls: 'danger' }] });
    if (!ok) return;
    await store.backend.updatePortalUser(u.id, { status: 'denied' });
    log('denyUser', u);
    render(el);
  }));
  el.querySelectorAll('[data-edit]').forEach((b) => b.addEventListener('click', async () => {
    const u = find(b.dataset.edit);
    const res = await roleDialog(t('editTitle', { name: u.name }), u.role, u.employer ?? '');
    if (!res) return;
    await store.backend.updatePortalUser(u.id, { role: res.role, employer: res.role === 'supervisor' ? res.employer : null });
    log('changeRole', u, `${res.role}${res.role === 'supervisor' ? ` · ${res.employer}` : ''}`);
    toast(t('savedOk'), 'ok');
    render(el);
  }));
  el.querySelectorAll('[data-toggle]').forEach((b) => b.addEventListener('click', async () => {
    const u = find(b.dataset.toggle);
    const status = u.status === 'active' ? 'disabled' : 'active';
    await store.backend.updatePortalUser(u.id, { status });
    log(status === 'active' ? 'enableUser' : 'disableUser', u);
    render(el);
  }));
  el.querySelectorAll('[data-remove]').forEach((b) => b.addEventListener('click', async () => {
    const u = find(b.dataset.remove);
    const ok = await modal({ title: t('removeTitle', { name: u.name }), body: `<p class="muted">${esc(t('removeHint'))}</p>`,
      actions: [{ label: t('cancel'), value: false, cls: 'outline' }, { label: t('remove'), value: true, cls: 'danger' }] });
    if (!ok) return;
    await store.backend.deletePortalUser(u.id);
    log('removeUser', u);
    render(el);
  }));
}

function roleDialog(title, role, employer) {
  const employers = store.employers();
  return modal({
    title,
    body: `<div class="form-grid">
      <div class="field"><label for="dRole">${esc(t('role'))}</label><select class="input" id="dRole">
        ${['supervisor', 'inspector', 'admin'].map((r) => `<option value="${r}" ${r === role ? 'selected' : ''}>${esc(t('role_' + r))} – ${esc(t('roleDesc_' + r))}</option>`).join('')}</select></div>
      <div class="field" id="dEmpField"><label for="dEmp">${esc(t('employerExact'))}</label>
        <input class="input" id="dEmp" list="dEmpList" value="${esc(employer)}" autocomplete="off">
        <datalist id="dEmpList">${employers.map((e) => `<option value="${esc(e)}">`).join('')}</datalist>
        <span class="small muted">${esc(t('employerMatchHint'))}</span></div>
      <div class="error-text" id="dErr"></div></div>`,
    onOpen: (m) => {
      const sync = () => m.querySelector('#dEmpField').classList.toggle('hidden', m.querySelector('#dRole').value !== 'supervisor');
      m.querySelector('#dRole').addEventListener('change', sync);
      sync();
    },
    actions: [
      { label: t('cancel'), value: null, cls: 'outline' },
      {
        label: t('save'),
        validate: (m) => {
          const ok = m.querySelector('#dRole').value !== 'supervisor' || m.querySelector('#dEmp').value.trim();
          m.querySelector('#dErr').textContent = ok ? '' : t('employerRequired');
          return !!ok;
        },
        value: (m) => ({ role: m.querySelector('#dRole').value, employer: m.querySelector('#dEmp').value.trim() }),
      },
    ],
  });
}
