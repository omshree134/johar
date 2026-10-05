/**
 * Issues a signed certificate whenever a passed attempt reaches Firestore.
 *
 * Token = "SS1." + base64url(JSON payload) + "." + base64url(Ed25519 signature)
 * The app verifies it offline with the public key in lib/core/config/cert_keys.dart.
 *
 * Setup:
 *   node ../scripts/generate_signing_key.js
 *   firebase functions:secrets:set CERT_SIGNING_KEY < ../scripts/cert_private_key.pem
 *   firebase deploy --only functions,firestore
 */
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const crypto = require("node:crypto");

initializeApp();
const SIGNING_KEY = defineSecret("CERT_SIGNING_KEY");

const PASS_MARK = 70; // keep in sync with kPassMark in lib/core/config/cert_keys.dart
const VALIDITY_DAYS = 365; // TODO: align with your refresher-training interval

function buildToken(payload, privateKeyPem) {
  const body = Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
  const key = crypto.createPrivateKey(privateKeyPem);
  const sig = crypto.sign(null, Buffer.from(body, "ascii"), key).toString("base64url");
  return `SS1.${body}.${sig}`;
}
exports.buildToken = buildToken; // exported for local testing

exports.issueCertificate = onDocumentCreated(
  { document: "attempts/{attemptId}", region: "asia-south1", secrets: [SIGNING_KEY] },
  async (event) => {
    const attempt = event.data?.data();
    if (!attempt) return;

    // Re-check the pass rule on the server instead of trusting the flag alone.
    const passed =
      attempt.passed === true &&
      typeof attempt.totalPercent === "number" &&
      attempt.totalPercent >= PASS_MARK &&
      (attempt.criticalMissed || []).length === 0;
    if (!passed) return;

    const db = getFirestore();
    const certId = event.params.attemptId; // one certificate per passed attempt
    const workerSnap = await db.doc(`workers/${attempt.workerId}`).get();
    const worker = workerSnap.data() || {};

    const issuedAt = Math.floor(Date.now() / 1000);
    const expiresAt = issuedAt + VALIDITY_DAYS * 86400;
    const payload = {
      v: 1,
      c: certId,
      w: attempt.workerId,
      n: worker.name || "",
      e: worker.employeeId || "",
      m: attempt.moduleId,
      s: Math.round(attempt.totalPercent),
      i: issuedAt,
      x: expiresAt,
    };

    try {
      await db.doc(`certificates/${certId}`).create({
        workerId: attempt.workerId,
        employeeId: worker.employeeId || "",
        employer: worker.employer || "",
        sector: worker.sector || "",
        moduleId: attempt.moduleId,
        score: payload.s,
        issuedAt,
        expiresAt,
        token: buildToken(payload, SIGNING_KEY.value()),
        status: "active",
        deviceUid: attempt.deviceUid,
        createdAt: FieldValue.serverTimestamp(),
      });
      logger.info("Certificate issued", { certId, moduleId: attempt.moduleId });
    } catch (err) {
      if (err.code === 6) return; // ALREADY_EXISTS: function retried, nothing to do
      throw err;
    }
  }
);
