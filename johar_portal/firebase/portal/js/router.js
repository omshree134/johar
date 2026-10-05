// Hash router: #/workers/123 -> pages/worker.js render(el, {id: '123'})
import { store } from './store.js';
import { $, $$ } from './ui.js';

const ROUTES = [
  { re: /^overview$/, load: () => import('./pages/overview.js'), nav: 'overview' },
  { re: /^workers$/, load: () => import('./pages/workers.js'), nav: 'workers' },
  { re: /^workers\/([\w-]+)$/, keys: ['id'], load: () => import('./pages/worker.js'), nav: 'workers' },
  { re: /^certificates$/, load: () => import('./pages/certificates.js'), nav: 'certificates' },
  { re: /^certificates\/([\w-]+)$/, keys: ['id'], load: () => import('./pages/certificate.js'), nav: 'certificates' },
  { re: /^verify$/, load: () => import('./pages/verify.js'), nav: 'verify', static: true },
  { re: /^reports$/, load: () => import('./pages/reports.js'), nav: 'reports' },
  { re: /^insights$/, load: () => import('./pages/insights.js'), nav: 'insights' },
  { re: /^users$/, load: () => import('./pages/users.js'), nav: 'users', roles: ['admin'], static: true },
];

let current = null; // { page, params, route }

export function go(path) { location.hash = `#/${path}`; }

export async function renderRoute() {
  if (!$('#view')) return; // signed out
  const [rawPath, qs] = location.hash.replace(/^#\/?/, '').split('?');
  const path = rawPath || 'overview';
  let route = ROUTES.find((r) => r.re.test(path));
  if (!route || (route.roles && !route.roles.includes(store.role))) { go('overview'); return; }
  const m = path.match(route.re);
  const params = {
    ...Object.fromEntries(new URLSearchParams(qs ?? '')),
    ...Object.fromEntries((route.keys ?? []).map((k, i) => [k, decodeURIComponent(m[i + 1])])),
  };
  current?.page.destroy?.();
  const page = await route.load();
  current = { page, params, route };
  $$('.nav a').forEach((a) => a.classList.toggle('on', a.dataset.nav === route.nav));
  document.querySelector('.shell')?.classList.remove('nav-open');
  const view = $('#view');
  view.scrollTop = 0;
  window.scrollTo(0, 0);
  await page.render(view, params);
}

/** Re-render the current page when data or filters change (not for pages with live state). */
export function refreshCurrent() {
  if (current && !current.route.static && $('#view')) current.page.render($('#view'), current.params);
}

export function startRouter() {
  window.addEventListener('hashchange', renderRoute);
  store.onChange(refreshCurrent);
  return renderRoute();
}
