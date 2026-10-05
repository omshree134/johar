// Pieces shared by several pages.
import { MODULES } from '../config.js';
import { t, lang } from '../i18n.js';
import { esc, signBadge, icon } from '../ui.js';
import { store } from '../store.js';

export const moduleTitle = (id) => {
  const m = MODULES.find((x) => x.id === id);
  return m ? m.title[lang()] ?? m.title.en : id;
};
export const moduleBadge = (id, size = 28) => {
  const m = MODULES.find((x) => x.id === id);
  return m ? signBadge(m.sign, m.glyph, size) : '';
};
export const moduleCell = (id, size = 24) => `<span class="module-cell">${moduleBadge(id, size)}<span>${esc(moduleTitle(id))}</span></span>`;
export const qText = (prompt) => (prompt ? prompt[lang()] ?? prompt.en : '');
export const shortId = (id = '') => id.slice(0, 8).toUpperCase();

export function pageHead(title, sub, actions = '', crumb = '') {
  return `<div class="page-head"><div class="grow">${crumb}<h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div>
    ${actions ? `<div class="actions no-print">${actions}</div>` : ''}</div>`;
}
export const crumb = (href, label) => `<a class="crumb no-print" href="${href}">${icon('back')}${esc(label)}</a>`;

export function loading(el) {
  if (store.loadedAt) return false;
  el.innerHTML = `<div class="empty">${esc(t('loading'))}</div>`;
  return true;
}

export function periodLabel() {
  const p = store.filters.period;
  return p ? t(`last${p}`) : t('allTime');
}
