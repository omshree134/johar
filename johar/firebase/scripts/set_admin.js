/**
 * Grants the admin claim used by firestore.rules and the web dashboard.
 *   GOOGLE_APPLICATION_CREDENTIALS=service-account.json node set_admin.js officer@example.com
 * The user must already exist in Firebase Auth: sign in to the portal once
 * with Google first, then run this. Use it once to create the first admin;
 * approve everyone else from the portal's Portal users page.
 */
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp({ credential: applicationDefault() });
const email = process.argv[2];
if (!email) throw new Error("Usage: node set_admin.js <email>");

getAuth()
  .getUserByEmail(email)
  .then((u) => getAuth().setCustomUserClaims(u.uid, { admin: true }))
  .then(() => console.log(`${email} is now an admin. They must sign out and in again.`));
