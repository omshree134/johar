// Cancel / reinstate a certificate, with a required reason and an audit entry.
import { store } from '../store.js';
import { t } from '../i18n.js';
import { esc, modal, toast } from '../ui.js';
import { shortId, moduleTitle } from './common.js';

export async function revokeFlow(cert) {
  const w = store.worker(cert.workerId);
  const reason = await modal({
    title: t('revokeTitle'),
    body: `<p class="muted">${esc(t('revokeHint', { name: w?.name ?? cert.employeeId, module: moduleTitle(cert.moduleId), id: shortId(cert.id) }))}</p>
      <div class="field"><label for="reason">${esc(t('reason'))}</label>
      <select class="input" id="reasonPick">
        <option value="">${esc(t('reasonPick'))}</option>
        <option>${esc(t('reason1'))}</option><option>${esc(t('reason2'))}</option><option>${esc(t('reason3'))}</option><option>${esc(t('reason4'))}</option>
      </select>
      <textarea class="input" id="reason" placeholder="${esc(t('reasonPh'))}" style="margin-top:8px"></textarea></div>
      <div class="error-text" id="reasonErr"></div>`,
    onOpen: (m) => m.querySelector('#reasonPick').addEventListener('change', (e) => { m.querySelector('#reason').value = e.target.value; }),
    actions: [
      { label: t('cancel'), value: null, cls: 'outline' },
      {
        label: t('revokeConfirm'), cls: 'danger',
        validate: (m) => { const ok = m.querySelector('#reason').value.trim().length >= 4; m.querySelector('#reasonErr').textContent = ok ? '' : t('reasonRequired'); return ok; },
        value: (m) => m.querySelector('#reason').value.trim(),
      },
    ],
  });
  if (!reason) return false;
  try {
    await store.backend.updateCertificate(cert.id, { status: 'revoked', revokedReason: reason });
    Object.assign(cert, { status: 'revoked', revokedReason: reason, revokedAt: new Date().toISOString() });
    store.backend.audit({ action: 'revokeCertificate', target: cert.id, targetLabel: shortId(cert.id), by: store.session.uid, byName: store.session.name, details: reason });
    toast(t('revokedOk'), 'ok');
    store._cache = null; store.emit();
    return true;
  } catch (e) { toast(e.message, 'error'); return false; }
}

export async function reinstateFlow(cert) {
  const ok = await modal({
    title: t('reinstateTitle'),
    body: `<p class="muted">${esc(t('reinstateHint'))}</p>${cert.revokedReason ? `<p><b>${esc(t('reason'))}:</b> ${esc(cert.revokedReason)}</p>` : ''}`,
    actions: [{ label: t('cancel'), value: false, cls: 'outline' }, { label: t('reinstate'), value: true, cls: 'success' }],
  });
  if (!ok) return false;
  try {
    await store.backend.updateCertificate(cert.id, { status: 'active', revokedReason: null });
    Object.assign(cert, { status: 'active', revokedReason: null, revokedAt: null });
    store.backend.audit({ action: 'reinstateCertificate', target: cert.id, targetLabel: shortId(cert.id), by: store.session.uid, byName: store.session.name, details: '' });
    toast(t('reinstatedOk'), 'ok');
    store._cache = null; store.emit();
    return true;
  } catch (e) { toast(e.message, 'error'); return false; }
}
