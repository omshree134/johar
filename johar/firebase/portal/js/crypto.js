// Offline certificate verification: Ed25519 signature over the payload.
// Token format: SS1.<base64url JSON>.<base64url signature>
const b64u = (s) => {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  return Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
};

export function parseToken(token) {
  const parts = String(token).trim().split('.');
  if (parts.length !== 3 || parts[0] !== 'SS1') return null;
  try {
    return { body: parts[1], sig: b64u(parts[2]), payload: JSON.parse(new TextDecoder().decode(b64u(parts[1]))) };
  } catch {
    return null;
  }
}

/** Returns { status: valid | forged | malformed | noKey, payload } */
export async function verifyToken(token, publicKeyB64) {
  const p = parseToken(token);
  if (!p) return { status: 'malformed' };
  if (!publicKeyB64 || publicKeyB64.startsWith('REPLACE')) return { status: 'noKey', payload: p.payload };
  const msg = new TextEncoder().encode(p.body);
  const pub = b64u(publicKeyB64);
  let ok;
  try {
    const key = await crypto.subtle.importKey('raw', pub, { name: 'Ed25519' }, false, ['verify']);
    ok = await crypto.subtle.verify({ name: 'Ed25519' }, key, p.sig, msg);
  } catch {
    // Browsers without Ed25519 in WebCrypto
    const ed = await import('https://cdn.jsdelivr.net/npm/@noble/ed25519@2.1.0/+esm');
    ok = await ed.verifyAsync(p.sig, msg, pub);
  }
  return ok ? { status: 'valid', payload: p.payload } : { status: 'forged' };
}

// Used by demo mode to sign sample certificates so verification is real.
export async function demoKeyPair() {
  try {
    const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
    const raw = new Uint8Array(await crypto.subtle.exportKey('raw', kp.publicKey));
    const pubB64 = btoa(String.fromCharCode(...raw)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    const sign = async (payload) => {
      const body = btoa(unescape(encodeURIComponent(JSON.stringify(payload)))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
      const sig = new Uint8Array(await crypto.subtle.sign({ name: 'Ed25519' }, kp.privateKey, new TextEncoder().encode(body)));
      return `SS1.${body}.${btoa(String.fromCharCode(...sig)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}`;
    };
    return { pubB64, sign };
  } catch {
    return null; // browser without Ed25519 signing: demo tokens stay unsigned
  }
}
