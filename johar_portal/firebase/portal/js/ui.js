// Small UI toolkit: escaping, icons, ISO sign badges, Sohrai pattern,
// charts, toasts, modal dialogs, CSV export. No framework, no build step.
import { t, lang } from './i18n.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
export const $ = (sel, root = document) => root.querySelector(sel);
export const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

// ---------------- Icons (24px, stroke = currentColor) ----------------
const P = {
  overview: '<rect x="3" y="3" width="8" height="10" rx="2"/><rect x="13" y="3" width="8" height="6" rx="2"/><rect x="13" y="11" width="8" height="10" rx="2"/><rect x="3" y="15" width="8" height="6" rx="2"/>',
  workers: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.3-5.5 6.5-5.5s5.9 1.9 6.5 5.5"/><circle cx="17.5" cy="9" r="2.5"/><path d="M16.5 14.6c2.6.1 4.4 1.7 5 4.4"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c.8-4.2 4-6.5 8-6.5s7.2 2.3 8 6.5"/>',
  certificate: '<circle cx="12" cy="9" r="6"/><path d="M8.5 13.8 7 22l5-2.6 5 2.6-1.5-8.2"/><path d="m9.6 9 1.6 1.6L14.6 7.4"/>',
  qr: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><path d="M14 14h3v3h-3zM20 14v.01M14 20h.01M17 20h4v-3"/>',
  report: '<path d="M6 2.5h8l5 5V20a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 20V4a1.5 1.5 0 0 1 1-1.5z"/><path d="M13.5 2.5V8H19M8.5 13h7M8.5 17h5"/>',
  insights: '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
  shield: '<path d="M12 2.5 4 5.5v6c0 5 3.4 8.6 8 10 4.6-1.4 8-5 8-10v-6z"/><path d="m8.8 12 2.3 2.3 4.2-4.3"/>',
  logout: '<path d="M14 4h4.5A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5H14"/><path d="M10 16.5 5.5 12 10 7.5M5.5 12H15"/>',
  search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m20 20-4.8-4.8"/>',
  download: '<path d="M12 3v12M7 10.5 12 15.5l5-5M4 20h16"/>',
  print: '<path d="M7 8V3h10v5"/><rect x="3" y="8" width="18" height="9" rx="2"/><path d="M7 14h10v7H7z"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.7 3.7 5.7 3.7 9s-1.2 6.3-3.7 9c-2.5-2.7-3.7-5.7-3.7-9s1.2-6.3 3.7-9z"/>',
  check: '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
  x: '<path d="M6 6l12 12M18 6 6 18"/>',
  alert: '<path d="M12 3.5 2.5 20h19z"/><path d="M12 10v4.5M12 17.2v.01"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
  back: '<path d="M15 5 8 12l7 7"/>',
  next: '<path d="m9 5 7 7-7 7"/>',
  menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
  camera: '<path d="M4 8h3l1.5-2.5h7L17 8h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.5"/>',
  refresh: '<path d="M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7"/>',
  ban: '<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>',
  brain: '<path d="M12 5a3 3 0 0 0-5.8-1A3.5 3.5 0 0 0 4 10a3.5 3.5 0 0 0 1.5 6.5A3 3 0 0 0 12 19zM12 5a3 3 0 0 1 5.8-1A3.5 3.5 0 0 1 20 10a3.5 3.5 0 0 1-1.5 6.5A3 3 0 0 1 12 19z"/>',
  hourglass: '<path d="M6 3h12M6 21h12M7 3c0 5 10 5 10 9s-10 4-10 9M17 3c0 5-10 5-10 9"/>',
  inbox: '<path d="M3 13h5l1.5 3h5L16 13h5"/><path d="M5 5h14l2 8v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-6z"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3.5 6.5 8.5 7 8.5-7"/>',
  eye: '<path d="M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  list: '<path d="M9 6h11M9 12h11M9 18h11M4 6h.01M4 12h.01M4 18h.01"/>',
};
export const icon = (name, cls = '') =>
  `<svg class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[name] ?? ''}</svg>`;

export const googleLogo = () => `<svg viewBox="0 0 48 48" width="20" height="20" aria-hidden="true">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>`;

export const logo = (size = 26) => `<svg viewBox="0 0 32 32" width="${size}" height="${size}" aria-hidden="true">
  <path d="M16 3 29 16 16 29 3 16Z" fill="none" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>
  <path d="M16 9.5 22.5 16 16 22.5 9.5 16Z" fill="none" stroke="rgba(255,255,255,.55)" stroke-width="1.8" stroke-linejoin="round"/>
  <circle cx="16" cy="16" r="2.8" fill="#B0532A"/></svg>`;

// ---------------- ISO 7010 sign badges (same shapes as the app) ----------------
const GLYPH = {
  fire: (c) => `<path d="M16 7c1 3.5 5 5.2 5 10a5 5 0 0 1-10 0c0-2.3 1.2-3.6 2.3-4.8.2 1.6 1 2.6 2.2 2.8-.4-2.8-.2-5.5.5-8z" fill="${c}"/>`,
  gas: (c) => `<path d="M9 13.5c2-1.6 4-1.6 6 0s4 1.6 6 0M9 17.5c2-1.6 4-1.6 6 0s4 1.6 6 0M9 21.5c2-1.6 4-1.6 6 0s4 1.6 6 0" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
  machinery: (c) => `<g fill="${c}"><circle cx="16" cy="16" r="5"/>${[0, 45, 90, 135, 180, 225, 270, 315].map((a) => `<rect x="14.6" y="8" width="2.8" height="4" rx=".6" transform="rotate(${a} 16 16)"/>`).join('')}</g><circle cx="16" cy="16" r="2" fill="#fff"/>`,
  electric: (c) => `<path d="M17.5 7 10.5 17h5l-1.5 8 7-10.5h-5z" fill="${c}"/>`,
  firstaid: (c) => `<path d="M13.5 8h5v5.5H24v5h-5.5V24h-5v-5.5H8v-5h5.5z" fill="${c}"/>`,
};
export function signBadge(kind, glyph, size = 36) {
  const g = GLYPH[glyph] ?? GLYPH.fire;
  let shape, ink = '#fff';
  switch (kind) {
    case 'warning':
      shape = '<path d="M16 3.2 29.6 27.6H2.4Z" fill="#F4B400" stroke="#1E2226" stroke-width="2.2" stroke-linejoin="round"/>';
      ink = '#1E2226';
      return `<svg class="sign" width="${size}" height="${size}" viewBox="0 0 32 32" aria-hidden="true">${shape}<g transform="translate(16 19.6) scale(.6) translate(-16 -16)">${g(ink)}</g></svg>`;
    case 'prohibition':
      return `<svg class="sign" width="${size}" height="${size}" viewBox="0 0 32 32" aria-hidden="true"><circle cx="16" cy="16" r="15" fill="#fff"/>${g('#1E2226')}<circle cx="16" cy="16" r="13.2" fill="none" stroke="#C4201F" stroke-width="3.4"/><path d="M6.7 6.7 25.3 25.3" stroke="#C4201F" stroke-width="3.4"/></svg>`;
    case 'mandatory':
      shape = '<circle cx="16" cy="16" r="15" fill="#0B5CAD"/>'; break;
    case 'safeCondition':
      shape = '<rect x="1" y="1" width="30" height="30" rx="5" fill="#17784A"/>'; break;
    default:
      shape = '<rect x="1" y="1" width="30" height="30" rx="5" fill="#C4201F"/>';
  }
  return `<svg class="sign" width="${size}" height="${size}" viewBox="0 0 32 32" aria-hidden="true">${shape}${g(ink)}</svg>`;
}

// ---------------- Sohrai-inspired band ----------------
let sohraiId = 0;
export function sohrai(opacity = 0.18) {
  const id = `sohrai${++sohraiId}`;
  const line = `rgba(255,255,255,${opacity})`;
  return `<svg class="sohrai" aria-hidden="true" preserveAspectRatio="none"><defs>
    <pattern id="${id}" width="44" height="64" patternUnits="userSpaceOnUse">
      <path d="M22 14 L34 27 L22 40 L10 27 Z" fill="none" stroke="${line}" stroke-width="1.6"/>
      <circle cx="22" cy="27" r="2.4" fill="#B0532A"/>
      <circle cx="4" cy="4" r="1.3" fill="${line}"/><circle cx="13" cy="4" r="1.3" fill="${line}"/>
      <circle cx="31" cy="4" r="1.3" fill="${line}"/><circle cx="40" cy="4" r="1.3" fill="${line}"/>
      <path d="M0 62 L11 46 L22 62 L33 46 L44 62" fill="none" stroke="${line}" stroke-width="1.6"/>
    </pattern></defs><rect width="100%" height="100%" fill="url(#${id})"/></svg>`;
}

// ---------------- Formatting ----------------
const locale = () => (lang() === 'hi' ? 'hi-IN' : 'en-IN');
export const fmtDate = (d) => (d ? new Date(d).toLocaleDateString(locale(), { day: 'numeric', month: 'short', year: 'numeric' }) : '–');
export const fmtDateTime = (d) => (d ? new Date(d).toLocaleString(locale(), { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '–');
export const fmtNum = (n) => (n == null ? '–' : Number(n).toLocaleString(locale()));
export const pct = (v) => (v == null || Number.isNaN(v) ? '–' : `${Math.round(v)}%`);
export const initials = (name = '') => name.trim().split(/\s+/).slice(0, 2).map((p) => [...p][0] ?? '').join('').toUpperCase();
export const avatar = (name, photo, cls = '') =>
  `<span class="avatar ${cls}">${photo ? `<img src="${esc(photo)}" alt="" referrerpolicy="no-referrer">` : esc(initials(name))}</span>`;

const STATUS_ICON = { valid: 'check', expiring: 'clock', expired: 'alert', revoked: 'ban', none: '', passed: 'check', failed: 'x', pending: 'hourglass', active: 'check', disabled: 'ban' };
export const pill = (status, label) => `<span class="pill ${status}">${STATUS_ICON[status] ? icon(STATUS_ICON[status]) : ''}${esc(label ?? t(status))}</span>`;

export const empty = (msg, ic = 'inbox') => `<div class="empty">${icon(ic)}${esc(msg)}</div>`;

// ---------------- Toast & modal ----------------
export function toast(msg, kind = '') {
  let host = $('.toast-host');
  if (!host) { host = document.createElement('div'); host.className = 'toast-host'; document.body.append(host); }
  const el = document.createElement('div');
  el.className = `toast ${kind}`;
  el.textContent = msg;
  host.append(el);
  setTimeout(() => el.remove(), 3500);
}

/** Opens a dialog. `body` is HTML; resolves with the clicked action value or null. */
export function modal({ title, body = '', actions = [{ label: t('cancel'), value: null, cls: 'outline' }], onOpen }) {
  return new Promise((resolve) => {
    const back = document.createElement('div');
    back.className = 'modal-back';
    back.innerHTML = `<div class="modal" role="dialog" aria-modal="true" aria-label="${esc(title)}"><h2>${esc(title)}</h2>
      <div class="modal-body">${body}</div>
      <div class="actions">${actions.map((a, i) => `<button class="btn ${a.cls ?? ''}" data-i="${i}" type="button">${esc(a.label)}</button>`).join('')}</div></div>`;
    const close = (v) => { back.remove(); document.removeEventListener('keydown', onKey); resolve(v); };
    const onKey = (e) => { if (e.key === 'Escape') close(null); };
    back.addEventListener('click', (e) => { if (e.target === back) close(null); });
    $$('.actions button', back).forEach((b) => b.addEventListener('click', () => {
      const a = actions[+b.dataset.i];
      if (a.validate && !a.validate(back)) return;
      close(typeof a.value === 'function' ? a.value(back) : a.value);
    }));
    document.addEventListener('keydown', onKey);
    document.body.append(back);
    onOpen?.(back);
    ($('input, textarea, select', back) ?? $('.actions .btn:last-child', back))?.focus();
  });
}

// ---------------- CSV ----------------
export function downloadCsv(filename, rows) {
  const csv = rows.map((r) => r.map((v) => `"${String(v ?? '').replace(/"/g, '""')}"`).join(',')).join('\r\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })); // BOM so Excel reads Hindi
  a.download = filename;
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

// ---------------- Charts ----------------
export const colorFor = (v, pass) => (v >= pass ? 'var(--green)' : v >= pass - 20 ? 'var(--yellow)' : 'var(--red)');

/** Horizontal bars. items: [{label, sub, value 0..100, color, text}] */
export function barRows(items, { mark } = {}) {
  return items.map((i) => `<div class="bar-row" ${i.label ? '' : 'style="grid-template-columns:1fr 58px;margin:0"'}>${i.label ? `<div><strong>${i.label}</strong>${i.sub ? `<div class="muted small">${esc(i.sub)}</div>` : ''}</div>` : ''}
    <div class="bar"><span style="width:${Math.max(0, Math.min(100, i.value ?? 0))}%;background:${i.color}"></span>${mark != null ? `<i class="mark" style="left:${mark}%"></i>` : ''}</div>
    <div class="num" style="text-align:right;font-weight:700">${esc(i.text ?? pct(i.value))}</div></div>`).join('');
}

/** Line/area chart. series: [{name, color, values[]}], labels[] */
export function lineChart({ labels, series, height = 220, yMax }) {
  const W = 640, H = height, L = 36, R = 12, T = 12, B = 28;
  const max = yMax ?? Math.max(4, ...series.flatMap((s) => s.values)) * 1.15;
  const x = (i) => L + (labels.length <= 1 ? 0 : (i * (W - L - R)) / (labels.length - 1));
  const y = (v) => T + (H - T - B) * (1 - v / max);
  const ticks = [0, 0.25, 0.5, 0.75, 1].map((f) => Math.round(max * f));
  const grid = ticks.map((v) => `<line x1="${L}" x2="${W - R}" y1="${y(v)}" y2="${y(v)}" stroke="#E6EAE8"/><text x="${L - 6}" y="${y(v) + 4}" text-anchor="end">${v}</text>`).join('');
  const every = Math.ceil(labels.length / 8);
  const xl = labels.map((l, i) => (i % every === 0 || i === labels.length - 1 ? `<text x="${x(i)}" y="${H - 8}" text-anchor="middle">${esc(l)}</text>` : '')).join('');
  const paths = series.map((s, si) => {
    const pts = s.values.map((v, i) => `${x(i)},${y(v)}`).join(' ');
    const area = si === 0 ? `<polygon points="${x(0)},${y(0)} ${pts} ${x(s.values.length - 1)},${y(0)}" fill="${s.color}" opacity=".12"/>` : '';
    const dots = s.values.map((v, i) => `<circle cx="${x(i)}" cy="${y(v)}" r="3" fill="#fff" stroke="${s.color}" stroke-width="2"><title>${esc(s.name)} · ${esc(labels[i])}: ${v}</title></circle>`).join('');
    return `${area}<polyline points="${pts}" fill="none" stroke="${s.color}" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>${dots}`;
  }).join('');
  return `<svg class="chart" viewBox="0 0 ${W} ${H}" role="img">${grid}${xl}${paths}</svg>
    <div class="legend">${series.map((s) => `<span><i style="background:${s.color}"></i>${esc(s.name)}</span>`).join('')}</div>`;
}

/** Donut. segments: [{label, value, color}] */
export function donut(segments, centerTop, centerBottom) {
  const total = segments.reduce((s, x) => s + x.value, 0) || 1;
  const r = 70, c = 2 * Math.PI * r;
  let off = 0;
  const arcs = segments.filter((s) => s.value > 0).map((s) => {
    const len = (s.value / total) * c;
    const el = `<circle cx="100" cy="100" r="${r}" fill="none" stroke="${s.color}" stroke-width="26" stroke-dasharray="${len} ${c - len}" stroke-dashoffset="${-off}" transform="rotate(-90 100 100)"><title>${esc(s.label)}: ${s.value}</title></circle>`;
    off += len;
    return el;
  }).join('');
  return `<div style="display:flex;gap:20px;align-items:center;flex-wrap:wrap">
    <svg class="chart" viewBox="0 0 200 200" style="width:180px;flex:none"><circle cx="100" cy="100" r="${r}" fill="none" stroke="#EEF1F0" stroke-width="26"/>${arcs}
      <text x="100" y="98" text-anchor="middle" style="font-size:28px;font-weight:700;fill:#1E2226">${esc(centerTop)}</text>
      <text x="100" y="120" text-anchor="middle" style="font-size:12px">${esc(centerBottom)}</text></svg>
    <div class="stack" style="flex:1;min-width:150px">${segments.map((s) => `<div style="display:flex;align-items:center;gap:10px"><i style="width:12px;height:12px;border-radius:4px;background:${s.color}"></i><span style="flex:1">${esc(s.label)}</span><b class="num">${fmtNum(s.value)}</b></div>`).join('')}</div></div>`;
}

/** Vertical columns (histogram). */
export function columns({ labels, values, colors, height = 160 }) {
  const W = 640, H = height, B = 24, T = 16;
  const max = Math.max(1, ...values);
  const bw = (W / labels.length) * 0.7, gap = (W / labels.length) * 0.3;
  return `<svg class="chart" viewBox="0 0 ${W} ${H}" role="img">${values.map((v, i) => {
    const h = ((H - B - T) * v) / max, x = i * (bw + gap) + gap / 2;
    return `<rect x="${x}" y="${H - B - h}" width="${bw}" height="${h}" rx="6" fill="${colors?.[i] ?? 'var(--manganese)'}"><title>${esc(labels[i])}: ${v}</title></rect>
      <text x="${x + bw / 2}" y="${H - 8}" text-anchor="middle">${esc(labels[i])}</text>${v ? `<text x="${x + bw / 2}" y="${H - B - h - 4}" text-anchor="middle" style="font-weight:700;fill:#1E2226">${v}</text>` : ''}`;
  }).join('')}</svg>`;
}
