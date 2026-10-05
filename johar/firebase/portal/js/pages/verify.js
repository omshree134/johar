// Verify a certificate: scan its QR with the laptop/phone camera, paste the
// QR text, or type the 8-character ID. The signature check is offline; the
// cancellation check uses Firestore.
import { store, certificateStatus } from '../store.js';
import { t } from '../i18n.js';
import { esc, icon, pill, fmtDate, pct, toast } from '../ui.js';
import { verifyToken } from '../crypto.js';
import { pageHead, moduleCell, shortId } from './common.js';
import { revokeFlow } from './cert-actions.js';

let stream = null, raf = 0, detector = null;

export function destroy() { stopCamera(); }

function stopCamera() {
  cancelAnimationFrame(raf);
  stream?.getTracks().forEach((tr) => tr.stop());
  stream = null;
}

export function render(el) {
  el.innerHTML = `
    ${pageHead(t('verifyTitle'), t('verifySub'))}
    <div class="verify-grid">
      <div class="stack">
        <div class="card">
          <div class="camera" id="cam"><div><div style="margin-bottom:12px">${icon('camera')}</div>${esc(t('cameraOff'))}</div></div>
          <div style="display:flex;gap:8px;margin-top:12px">
            <button class="btn block" id="camBtn" type="button">${icon('camera')}${esc(t('startCamera'))}</button>
          </div>
        </div>
        <div class="card">
          <div class="field"><label for="manual">${esc(t('manualLabel'))}</label>
            <textarea class="input" id="manual" placeholder="${esc(t('manualPh'))}"></textarea></div>
          <button class="btn block" id="check" type="button" style="margin-top:10px">${icon('shield')}${esc(t('check'))}</button>
        </div>
      </div>
      <div id="result"><div class="card empty">${icon('qr')}${esc(t('verifyWaiting'))}</div></div>
    </div>`;

  el.querySelector('#check').addEventListener('click', () => {
    const v = el.querySelector('#manual').value.trim();
    if (v) check(el, v);
  });
  el.querySelector('#camBtn').addEventListener('click', () => (stream ? (stopCamera(), resetCam(el)) : startCamera(el)));
}

function resetCam(el) {
  el.querySelector('#cam').innerHTML = `<div><div style="margin-bottom:12px">${icon('camera')}</div>${esc(t('cameraOff'))}</div>`;
  el.querySelector('#camBtn').innerHTML = `${icon('camera')}${esc(t('startCamera'))}`;
}

async function startCamera(el) {
  try {
    stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false });
  } catch {
    toast(t('cameraDenied'), 'error');
    return;
  }
  const cam = el.querySelector('#cam');
  cam.innerHTML = '<video playsinline muted></video><div class="frame"></div>';
  const video = cam.querySelector('video');
  video.srcObject = stream;
  await video.play();
  el.querySelector('#camBtn').innerHTML = `${icon('x')}${esc(t('stopCamera'))}`;
  if ('BarcodeDetector' in window) {
    try { detector = new window.BarcodeDetector({ formats: ['qr_code'] }); } catch { detector = null; }
  }
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  let busy = false;
  const loop = async () => {
    if (!stream) return;
    if (!busy && video.readyState >= 2) {
      busy = true;
      let text = null;
      try {
        if (detector) {
          const codes = await detector.detect(video);
          text = codes[0]?.rawValue ?? null;
        } else if (window.jsQR) {
          canvas.width = video.videoWidth; canvas.height = video.videoHeight;
          ctx.drawImage(video, 0, 0);
          text = window.jsQR(ctx.getImageData(0, 0, canvas.width, canvas.height).data, canvas.width, canvas.height)?.data ?? null;
        }
      } catch { /* keep scanning */ }
      busy = false;
      if (text) {
        stopCamera(); resetCam(el);
        el.querySelector('#manual').value = text;
        navigator.vibrate?.(60);
        check(el, text);
        return;
      }
    }
    raf = requestAnimationFrame(loop);
  };
  loop();
}

async function check(el, input) {
  const out = el.querySelector('#result');
  out.innerHTML = `<div class="card empty">${esc(t('checking'))}</div>`;
  let sig = null, certId = null;
  if (input.startsWith('SS1.')) {
    sig = await verifyToken(input, store.publicKey);
    certId = sig.payload?.c ?? null;
  } else {
    const q = input.replace(/\s/g, '').toUpperCase();
    certId = store.data.certificates.find((c) => c.id.toUpperCase().startsWith(q))?.id ?? (q.length > 20 ? input.trim() : null);
  }
  let doc = null;
  if (certId) {
    try { doc = await store.backend.getCertificate(certId); } catch { doc = null; }
  }

  // Decide the verdict. The signature is the proof; Firestore adds cancellation state.
  let cls = 'bad', ic = 'x', title = t('vMalformed'), note = '';
  if (sig?.status === 'forged') { title = t('vForged'); note = t('vForgedNote'); }
  else if (!sig && !doc) { title = t('vNotFound'); }
  else if (doc?.status === 'revoked') { title = t('vRevoked'); ic = 'ban'; note = doc.revokedReason ? `${t('reason')}: ${doc.revokedReason}` : ''; }
  else if (doc && certificateStatus(doc) === 'expired') { cls = 'warn'; ic = 'clock'; title = t('vExpired'); note = t('vExpiredNote'); }
  else if (sig?.status === 'noKey') { cls = 'warn'; ic = 'alert'; title = t('vNoKey'); }
  else if (sig?.status === 'valid' || doc) {
    cls = 'ok'; ic = 'check'; title = t('vGenuine');
    note = sig?.status === 'valid' ? (doc ? t('vBoth') : t('vSigOnly')) : t('vRecordOnly');
  }
  const p = sig?.payload ?? {};
  const w = store.worker(doc?.workerId ?? p.w);
  const facts = doc || sig?.payload ? `<dl class="kv">
      <dt>${esc(t('name'))}</dt><dd>${esc(w?.name ?? p.n ?? '–')}</dd>
      <dt>${esc(t('workerId'))}</dt><dd>${esc(doc?.employeeId ?? p.e ?? '–')}</dd>
      ${doc?.employer ? `<dt>${esc(t('employer'))}</dt><dd>${esc(doc.employer)}</dd>` : ''}
      <dt>${esc(t('module'))}</dt><dd>${moduleCell(doc?.moduleId ?? p.m, 20)}</dd>
      <dt>${esc(t('score'))}</dt><dd>${pct(doc?.score ?? p.s)}</dd>
      <dt>${esc(t('issued'))}</dt><dd>${esc(fmtDate((doc?.issuedAt ?? p.i) * 1000))}</dd>
      <dt>${esc(t('validUntil'))}</dt><dd>${esc(fmtDate((doc?.expiresAt ?? p.x) * 1000))}</dd>
      <dt>${esc(t('certId'))}</dt><dd>${esc(shortId(doc?.id ?? p.c ?? ''))}</dd>
      ${doc ? `<dt>${esc(t('status'))}</dt><dd>${pill(certificateStatus(doc))}</dd>` : ''}</dl>` : '';

  out.innerHTML = `<div class="verdict ${cls}">
    <div class="big"><span class="ico">${icon(ic)}</span><div><h2 style="font-size:22px">${esc(title)}</h2>${note ? `<div class="muted">${esc(note)}</div>` : ''}</div></div>
    ${sig?.status === 'forged' ? '' : facts}
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:16px" class="no-print">
      ${doc ? `<a class="btn secondary" href="#/certificates/${doc.id}">${icon('certificate')}${esc(t('viewCertificate'))}</a>` : ''}
      ${w ? `<a class="btn secondary" href="#/workers/${w.id}">${icon('user')}${esc(t('viewWorker'))}</a>` : ''}
      ${doc && store.canRevoke && doc.status !== 'revoked' ? `<button class="btn danger" id="rv" type="button">${icon('ban')}${esc(t('revoke'))}</button>` : ''}
    </div></div>`;
  out.querySelector('#rv')?.addEventListener('click', async () => {
    const local = store.data.certificates.find((c) => c.id === doc.id) ?? doc;
    if (await revokeFlow(local)) check(el, input);
  });
}
