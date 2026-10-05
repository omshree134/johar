// ===== Fill these in =====
// Firebase console > Project settings > Your apps > Web app > SDK config
export const firebaseConfig = {
  apiKey: 'REPLACE',
  authDomain: 'joharorg.firebaseapp.com',
  projectId: 'joharorg',
  appId: '1:370462837536:web:joharorg',
};

// Same public key as the app's lib/core/config/cert_keys.dart
export const CERT_PUBLIC_KEY_B64 = 'Clc0OWfREqD2OcnMAEELxg2mJH_A11-BdKX2yxqEZiQ';

// ===== Policy (keep in sync with the app and Cloud Function) =====
export const PASS_MARK = 70;
export const EXPIRY_WARNING_DAYS = 30;
export const NEW_WORKER_DAYS = 30; // DGMS: many fatalities involve workers with < 30 days of orientation
export const RETENTION_DAYS = 7;

// Training modules shown in the portal. `sign` = ISO 7010 family, same as the app.
export const MODULES = [
  { id: 'fire', sign: 'fireEquipment', glyph: 'fire', title: { en: 'Fire and explosion', hi: 'आग और विस्फोट' } },
  { id: 'gas', sign: 'warning', glyph: 'gas', title: { en: 'Gas leak and confined space', hi: 'गैस रिसाव और बंद जगह' } },
  { id: 'machinery', sign: 'prohibition', glyph: 'machinery', title: { en: 'Machinery safety', hi: 'मशीनरी सुरक्षा' } },
  { id: 'electrical', sign: 'mandatory', glyph: 'electric', title: { en: 'Electrical safety', hi: 'बिजली सुरक्षा' } },
  { id: 'firstaid', sign: 'safeCondition', glyph: 'firstaid', title: { en: 'First aid and evacuation', hi: 'प्राथमिक चिकित्सा और निकासी' } },
];

export const SECTORS = ['coal', 'steel', 'mica'];

/**
 * Portal roles:
 *  admin      – everything, including approving portal users
 *  inspector  – sees all employers, verifies and cancels certificates, reports
 *  supervisor – sees only their own employer's workers (enforced by Firestore rules)
 */
export const ROLES = ['admin', 'inspector', 'supervisor'];
