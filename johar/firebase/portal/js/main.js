// Boot: pick backend, gate access by role, render the shell.
import { store } from './store.js';
import { t, lang, setLang, onLang } from './i18n.js';
import { $, esc, icon, logo, sohrai, googleLogo, avatar, pill, toast, fmtDateTime } from './ui.js';
import { startRouter, renderRoute } from './router.js';
import { SECTORS, ROLES } from './config.js';

const app = $('#app');
const params = new URLSearchParams(location.search);
const demoMode = params.get('demo');
let rerenderGate = null; // re-draws the current sign-in screen after a language switch
let routerStarted = false;
let unsubscribeFilters = null;

async function boot() {
  app.innerHTML = `<div class="gate" style="grid-template-columns:1fr"><div class="panel"><div class="muted">${esc(t('loading'))}</div></div></div>`;
  if (demoMode) {
    const { makeDemoBackend } = await import('./backend-demo.js');
    store.backend = makeDemoBackend(demoMode);
  } else {
    store.backend = (await import('./backend-firebase.js')).backend;
  }
  try {
    await store.backend.init();
  } catch (e) {
    app.innerHTML = `<div class="gate" style="grid-template-columns:1fr"><div class="panel"><div class="box card">
      <h1>${esc(t('setupNeeded'))}</h1><p class="muted">${esc(t('setupHint'))}</p><pre class="small">${esc(e.message)}</pre>
      <a class="btn" href="?demo=1">${esc(t('openDemo'))}</a></div></div></div>`;
    return;
  }
  onLang(() => (store.session ? renderShell() : rerenderGate?.()));
  store.backend.onAuth(handleAuth);
}

async function handleAuth(user) {
  if (!user) { store.session = null; return renderLogin(); }
  const base = { uid: user.uid, name: user.displayName || user.email, email: user.email, photoURL: user.photoURL };
  try {
    const claims = await store.backend.claims(user);
    if (claims.admin === true) {
      store.session = { ...base, role: 'admin' };
    } else {
      const profile = await store.backend.getPortalUser(user.uid);
      if (!profile) return renderRequestAccess(base);
      if (profile.status === 'pending') return renderWaiting(base, profile);
      if (profile.status !== 'active' || !ROLES.includes(profile.role)) return renderWaiting(base, profile, true);
      store.session = { ...base, role: profile.role, employer: profile.employer ?? null };
      store.backend.touchLogin(user.uid, { name: base.name, photoURL: base.photoURL ?? null });
    }
  } catch (e) {
    toast(e.message, 'error');
    return renderLogin(e.message);
  }
  if (store.role === 'supervisor') store.filters.employer = '';
  renderShell();
  await store.load();
}

// ---------------- Sign-in ----------------
function artPanel() {
  return `<div class="art">
    <div style="display:flex;align-items:center;gap:12px">${logo(34)}<b style="font-size:18px">Johar</b></div>
    <div class="word">जोहार</div>
    <p class="tag">${esc(t('gateTag'))}</p>
    <div class="facts-row">
      <div><b>3</b><span>${esc(t('gateFact1'))}</span></div>
      <div><b>EN · हिं · ᱥᱟᱱ</b><span>${esc(t('gateFact2'))}</span></div>
      <div><b>QR</b><span>${esc(t('gateFact3'))}</span></div>
    </div>${sohrai(0.2)}</div>`;
}
const langBtn = () => `<button class="btn outline sm lang" id="langBtn" type="button">${icon('globe')}${lang() === 'en' ? 'हिन्दी' : 'English'}</button>`;
const bindLang = () => $('#langBtn')?.addEventListener('click', () => setLang(lang() === 'en' ? 'hi' : 'en'));

function renderLogin(error = '') {
  rerenderGate = () => renderLogin();
  app.innerHTML = `${demoBanner()}<div class="gate">${artPanel()}<div class="panel">${langBtn()}<div class="box">
    <h1>${esc(t('signInTitle'))}</h1><p>${esc(t('signInHint'))}</p>
    <button class="btn lg block google-btn" id="google" type="button">${googleLogo()}${esc(t('signInGoogle'))}</button>
    <div class="divider">${esc(t('orEmail'))}</div>
    <form id="emailForm" class="form-grid">
      <div class="field"><label for="em">${esc(t('email'))}</label><input class="input" id="em" type="email" autocomplete="username" required></div>
      <div class="field"><label for="pw">${esc(t('password'))}</label><input class="input" id="pw" type="password" autocomplete="current-password" required></div>
      <button class="btn block" type="submit">${esc(t('signIn'))}</button>
    </form>
    <div class="error-text" id="err" role="alert">${esc(error)}</div>
    <p class="small muted" style="margin-top:18px">${esc(t('signInNote'))}</p>
  </div></div></div>`;
  bindLang();
  const fail = (e) => { $('#err').textContent = friendlyAuthError(e); };
  $('#google').addEventListener('click', () => store.backend.signInGoogle().catch(fail));
  $('#emailForm').addEventListener('submit', (e) => {
    e.preventDefault();
    store.backend.signInEmail($('#em').value, $('#pw').value).catch(fail);
  });
}

function friendlyAuthError(e) {
  const code = e?.code ?? '';
  if (code.includes('popup-closed')) return t('errPopupClosed');
  if (code.includes('invalid-credential') || code.includes('wrong-password') || code.includes('user-not-found')) return t('errCredentials');
  if (code.includes('unauthorized-domain')) return t('errDomain');
  if (code.includes('network')) return t('errNetwork');
  return e?.message ?? String(e);
}

function renderRequestAccess(user) {
  rerenderGate = () => renderRequestAccess(user);
  app.innerHTML = `${demoBanner()}<div class="gate">${artPanel()}<div class="panel">${langBtn()}<div class="box">
    <div style="display:flex;gap:12px;align-items:center;margin-bottom:16px">${avatar(user.name, user.photoURL)}<div><b>${esc(user.name)}</b><div class="small muted">${esc(user.email)}</div></div></div>
    <h1>${esc(t('requestTitle'))}</h1><p>${esc(t('requestHint'))}</p>
    <form id="reqForm" class="form-grid">
      <div class="field"><label for="role">${esc(t('requestRole'))}</label>
        <select class="input" id="role"><option value="supervisor">${esc(t('role_supervisor'))}</option><option value="inspector">${esc(t('role_inspector'))}</option></select></div>
      <div class="field"><label for="org">${esc(t('organisation'))}</label><input class="input" id="org" required placeholder="${esc(t('organisationPh'))}"></div>
      <div class="field" id="empField"><label for="emp">${esc(t('employerExact'))}</label><input class="input" id="emp" placeholder="BCCL Jharia Colliery"></div>
      <div class="field"><label for="phone">${esc(t('phone'))}</label><input class="input" id="phone" type="tel" autocomplete="tel"></div>
      <div class="field"><label for="note">${esc(t('note'))}</label><textarea class="input" id="note" placeholder="${esc(t('notePh'))}"></textarea></div>
      <button class="btn block" type="submit">${esc(t('sendRequest'))}</button>
      <button class="btn ghost block" type="button" id="out">${esc(t('signOut'))}</button>
    </form><div class="error-text" id="err"></div></div></div></div>`;
  bindLang();
  $('#role').addEventListener('change', () => $('#empField').classList.toggle('hidden', $('#role').value !== 'supervisor'));
  $('#out').addEventListener('click', () => store.backend.signOut());
  $('#reqForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      const profile = {
        name: user.name, email: user.email, photoURL: user.photoURL ?? null,
        requestedRole: $('#role').value, organisation: $('#org').value.trim(),
        requestedEmployer: $('#role').value === 'supervisor' ? $('#emp').value.trim() : null,
        phone: $('#phone').value.trim(), note: $('#note').value.trim(),
      };
      await store.backend.requestAccess(user.uid, profile);
      renderWaiting(user, { ...profile, status: 'pending' });
    } catch (err) { $('#err').textContent = err.message; }
  });
}

function renderWaiting(user, profile, denied = false) {
  rerenderGate = () => renderWaiting(user, profile, denied);
  app.innerHTML = `${demoBanner()}<div class="gate">${artPanel()}<div class="panel">${langBtn()}<div class="box">
    <div class="card" style="text-align:center">
      <div style="width:64px;height:64px;border-radius:20px;margin:0 auto 14px;display:grid;place-items:center;background:${denied ? 'var(--red-soft)' : 'var(--yellow-soft)'};color:${denied ? 'var(--red)' : 'var(--yellow-ink)'}">${icon(denied ? 'ban' : 'hourglass')}</div>
      <h1>${esc(t(denied ? 'deniedTitle' : 'waitingTitle'))}</h1>
      <p class="muted">${esc(t(denied ? 'deniedHint' : 'waitingHint'))}</p>
      <dl class="kv" style="text-align:left"><dt>${esc(t('email'))}</dt><dd>${esc(user.email)}</dd>
        ${profile.requestedRole ? `<dt>${esc(t('requestRole'))}</dt><dd>${esc(t('role_' + profile.requestedRole))}</dd>` : ''}
        ${profile.organisation ? `<dt>${esc(t('organisation'))}</dt><dd>${esc(profile.organisation)}</dd>` : ''}</dl>
      <div style="display:flex;gap:8px;justify-content:center;margin-top:18px">
        <button class="btn secondary" id="check" type="button">${icon('refresh')}${esc(t('checkAgain'))}</button>
        <button class="btn ghost" id="out" type="button">${esc(t('signOut'))}</button></div>
    </div></div></div></div>`;
  bindLang();
  $('#out').addEventListener('click', () => store.backend.signOut());
  $('#check').addEventListener('click', () => location.reload());
}

// ---------------- Shell ----------------
function demoBanner() {
  return demoMode ? `<div class="demo-banner">${esc(t('demoBanner'))}</div>` : '';
}

function renderShell() {
  const s = store.session;
  const nav = (id, ic, label, extra = '') => `<a href="#/${id}" data-nav="${id}">${icon(ic)}<span>${esc(label)}</span>${extra}</a>`;
  app.innerHTML = `${demoBanner()}<div class="shell">
    <aside class="sidebar">
      <div class="brand"><div class="logo">${logo()}</div><div><div class="name">जोहार</div><div class="sub">${esc(t('brandSub'))}</div></div></div>
      <nav class="nav" aria-label="Main">
        ${nav('overview', 'overview', t('navOverview'))}
        ${nav('workers', 'workers', t('navWorkers'))}
        ${nav('certificates', 'certificate', t('navCertificates'))}
        ${nav('verify', 'qr', t('navVerify'))}
        <div class="section">${esc(t('navAnalyse'))}</div>
        ${nav('insights', 'insights', t('navInsights'))}
        ${nav('reports', 'report', t('navReports'))}
        ${s.role === 'admin' ? `<div class="section">${esc(t('navAdmin'))}</div>${nav('users', 'shield', t('navUsers'), '<span class="badge hidden" id="reqBadge"></span>')}` : ''}
      </nav>
      <div class="me">${avatar(s.name, s.photoURL)}<div class="who"><b>${esc(s.name)}</b>${pill(s.role, t('role_' + s.role))}</div>
        <button class="icon-btn" id="signOut" type="button" title="${esc(t('signOut'))}" aria-label="${esc(t('signOut'))}">${icon('logout')}</button></div>
      ${sohrai(0.16)}
    </aside>
    <div class="main">
      <div class="topbar">
        <button class="icon-btn menu-btn" id="menu" type="button" aria-label="Menu">${icon('menu')}</button>
        <div class="filters">
          <select class="input" id="fSector" aria-label="${esc(t('sector'))}"></select>
          ${store.scopeEmployer ? `<span class="scope">${esc(store.scopeEmployer)}</span>` : `<select class="input" id="fEmployer" aria-label="${esc(t('employer'))}"></select>`}
          <select class="input" id="fPeriod" aria-label="${esc(t('period'))}">
            ${[[30, 'last30'], [90, 'last90'], [365, 'last365'], [0, 'allTime']].map(([v, k]) => `<option value="${v}">${esc(t(k))}</option>`).join('')}
          </select>
        </div>
        <span class="small muted" id="updated"></span>
        <button class="icon-btn" id="reload" type="button" title="${esc(t('refresh'))}" aria-label="${esc(t('refresh'))}">${icon('refresh')}</button>
        <button class="btn outline sm" id="langBtn" type="button">${icon('globe')}${lang() === 'en' ? 'हिन्दी' : 'English'}</button>
      </div>
      <main class="view" id="view" tabindex="-1"></main>
    </div><div class="scrim" id="scrim"></div></div>`;

  $('#menu').addEventListener('click', () => $('.shell').classList.toggle('nav-open'));
  $('#scrim').addEventListener('click', () => $('.shell').classList.remove('nav-open'));
  $('#signOut').addEventListener('click', () => store.backend.signOut());
  bindLang();
  $('#reload').addEventListener('click', async () => { await store.load(); toast(t('refreshed'), 'ok'); });
  $('#fPeriod').value = String(store.filters.period);
  $('#fPeriod').addEventListener('change', (e) => store.setFilter('period', +e.target.value));
  const fillFilters = () => {
    if (!$('#fSector')) return;
    $('#fSector').innerHTML = `<option value="">${esc(t('allSectors'))}</option>` + SECTORS.map((x) => `<option value="${x}">${esc(t(x))}</option>`).join('');
    $('#fSector').value = store.filters.sector;
    const emp = $('#fEmployer');
    if (emp) {
      emp.innerHTML = `<option value="">${esc(t('allEmployers'))}</option>` + store.employers().map((x) => `<option>${esc(x)}</option>`).join('');
      emp.value = store.filters.employer;
    }
    $('#updated').textContent = store.loadedAt ? `${t('updated')} ${fmtDateTime(store.loadedAt)}` : '';
  };
  $('#fSector').addEventListener('change', (e) => store.setFilter('sector', e.target.value));
  $('#fEmployer')?.addEventListener('change', (e) => store.setFilter('employer', e.target.value));
  fillFilters();
  unsubscribeFilters?.();
  unsubscribeFilters = store.onChange(fillFilters);

  if (s.role === 'admin') {
    store.backend.listPortalUsers().then((users) => {
      const n = users.filter((u) => u.status === 'pending').length;
      const b = $('#reqBadge');
      if (b && n) { b.textContent = n; b.classList.remove('hidden'); }
    }).catch(() => {});
  }
  if (!routerStarted) { routerStarted = true; startRouter(); } else renderRoute();
}

boot();
