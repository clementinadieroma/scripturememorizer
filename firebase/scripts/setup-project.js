/**
 * Enable Email/Password auth on Spark (free) plan.
 * Run from firebase/: node scripts/setup-project.js
 * Equivalent to: firebase deploy --only auth
 */
const { execSync } = require("child_process");
const path = require("path");

try {
  execSync("firebase deploy --only auth", {
    cwd: path.join(__dirname, ".."),
    stdio: "inherit",
  });
  console.log("Auth providers deployed.");
} catch (err) {
  console.error("Auth deploy failed. Ensure firebase.json contains:");
  console.error('  "auth": { "providers": { "emailPassword": true } }');
  process.exit(1);
}
