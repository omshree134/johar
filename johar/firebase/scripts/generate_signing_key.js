/**
 * Creates the Ed25519 key pair for certificates.
 *   node generate_signing_key.js
 * - cert_private_key.pem  -> upload as the CERT_SIGNING_KEY secret, then DELETE the file.
 *                            Never commit it; anyone holding it can forge certificates.
 * - prints the public key -> paste into lib/core/config/cert_keys.dart
 */
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const { publicKey, privateKey } = crypto.generateKeyPairSync("ed25519");
const out = path.join(__dirname, "cert_private_key.pem");
fs.writeFileSync(out, privateKey.export({ type: "pkcs8", format: "pem" }), { mode: 0o600 });

console.log("Private key written to", out);
console.log("\nPaste into lib/core/config/cert_keys.dart:\n");
console.log(`const String certPublicKeyB64 = '${publicKey.export({ format: "jwk" }).x}';`);
