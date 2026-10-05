// Single certificate: printable A4 landscape copy with the same QR the app shows.
import { store, certificateStatus } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, pill, fmtDate, pct, sohrai, logo, empty } from '../ui.js';
import { pageHead, crumb, moduleBadge, moduleTitle, loading, shortId } from './common.js';
import { revokeFlow, reinstateFlow } from './cert-actions.js';
import { MODULES } from '../config.js';

function qrSvg(text) {
  if (!window.qrcode || !text) return '';
  const qr = window.qrcode(0, 'M');
  qr.addData(text);
  qr.make();
  return qr.createSvgTag({ cellSize: 4, margin: 0, scalable: true });
}

export function render(el, { id }) {
  if (loading(el)) return;
  const c = store.data.certificates.find((x) => x.id === id);
  if (!c) { el.innerHTML = `${crumb('#/certificates', t('navCertificates'))}${empty(t('notFoundCert'), 'certificate')}`; return; }
  const w = store.worker(c.workerId);
  const s = certificateStatus(c);
  const m = MODULES.find((x) => x.id === c.moduleId);
  // Printed certificates are always bilingual, whatever the portal language.
  const bi = (k) => `${esc(t(k, {}, 'en'))} <span style="font-weight:600;opacity:.75">/ ${esc(t(k, {}, 'hi'))}</span>`;

  el.innerHTML = `
    ${pageHead(`${t('certificate')} ${shortId(c.id)}`, `${w?.name ?? c.employeeId} · ${moduleTitle(c.moduleId)}`,
      `${store.canRevoke ? (s === 'revoked'
        ? `<button class="btn success" id="reinstate" type="button">${esc(t('reinstate'))}</button>`
        : `<button class="btn outline" id="revoke" type="button" style="color:var(--red)">${icon('ban')}${esc(t('revoke'))}</button>`) : ''}
       <button class="btn" id="print" type="button">${icon('print')}${esc(t('print'))}</button>`,
      crumb('#/certificates', t('navCertificates')))}
    ${s !== 'valid' ? `<div class="card no-print" style="margin-bottom:16px;display:flex;gap:12px;align-items:center">${pill(s)}
      <span>${esc(t('certNotice_' + s))}${c.revokedReason ? ` <b>${esc(t('reason'))}:</b> ${esc(c.revokedReason)}` : ''}</span></div>` : ''}
    <div class="cert-sheet">
      <div class="cert-inner">
        <div>
          <div class="cert-brand"><span style="background:var(--manganese);border-radius:12px;width:40px;height:40px;display:grid;place-items:center">${logo(24)}</span>जोहार · Johar</div>
          <div class="cert-title">${bi('certHeading')}</div>
          <div class="muted" style="margin-top:14px">${bi('certifiesThat')}</div>
          <div class="cert-name">${esc(w?.name ?? '')}</div>
          <div class="muted">${esc(c.employeeId)} · ${esc(c.employer)}</div>
          <div class="muted" style="margin-top:18px">${bi('completedTraining')}</div>
          <div class="cert-module">${moduleBadge(c.moduleId, 44)}<span>${esc(m?.title.en ?? c.moduleId)}<div class="muted" style="font-size:16px">${esc(m?.title.hi ?? '')}</div></span></div>
          <dl class="cert-meta">
            <div><dt>${bi('score')}</dt><dd>${pct(c.score)}</dd></div>
            <div><dt>${bi('issued')}</dt><dd>${esc(fmtDate(c.issuedAt * 1000))}</dd></div>
            <div><dt>${bi('validUntil')}</dt><dd>${esc(fmtDate(c.expiresAt * 1000))}</dd></div>
            <div><dt>${bi('certId')}</dt><dd>${esc(shortId(c.id))}</dd></div>
          </dl>
        </div>
        <div class="cert-qr">
          <div class="qr">${qrSvg(c.token)}</div>
          <p class="small muted" style="max-width:210px;margin:10px auto 0">${esc(t('qrNote', {}, 'en'))}<br>${esc(t('qrNote', {}, 'hi'))}</p>
          ${s === 'revoked' ? `<div style="margin-top:12px">${pill('revoked', t('revoked', {}, 'en').toUpperCase())}</div>` : ''}
        </div>
        ${sohrai(0.2)}
      </div>
    </div>`;

  el.querySelector('#print').addEventListener('click', () => window.print());
  el.querySelector('#revoke')?.addEventListener('click', async () => { if (await revokeFlow(c)) render(el, { id }); });
  el.querySelector('#reinstate')?.addEventListener('click', async () => { if (await reinstateFlow(c)) render(el, { id }); });
}
