/**
 * Initialize Firebase Storage default bucket (Spark plan OK).
 * Run from firebase/: node scripts/setup-storage.js
 */
const fs = require("fs");
const path = require("path");
const https = require("https");

const PROJECT_ID = "scripture-memorizer-app";
const STORAGE_BUCKET = `${PROJECT_ID}.firebasestorage.app`;
const STORAGE_LOCATION = "US";

function loadAccessToken() {
  const file = path.join(
    process.env.USERPROFILE,
    ".config",
    "configstore",
    "firebase-tools.json",
  );
  const token = JSON.parse(fs.readFileSync(file)).tokens?.access_token;
  if (!token) throw new Error("Run `firebase login` first.");
  return token;
}

function request(method, url, token, body) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const headers = { Authorization: `Bearer ${token}` };
    if (payload) {
      headers["Content-Type"] = "application/json";
      headers["Content-Length"] = Buffer.byteLength(payload);
    }
    const req = https.request(url, { method, headers }, (res) => {
      let raw = "";
      res.on("data", (c) => (raw += c));
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(raw);
          return;
        }
        reject(new Error(`${method} ${res.statusCode}: ${raw}`));
      });
    });
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function enableApi(token, api) {
  const url =
    "https://serviceusage.googleapis.com/v1/projects/" +
    PROJECT_ID +
    "/services/" +
    api +
    ":enable";
  try {
    await request("POST", url, token, {});
  } catch (err) {
    if (!String(err.message).includes("ALREADY_ENABLED")) {
      console.warn(api, err.message.slice(0, 120));
    }
  }
}

async function main() {
  const token = loadAccessToken();
  await enableApi(token, "firebasestorage.googleapis.com");
  await enableApi(token, "storage.googleapis.com");

  const createUrl =
    "https://storage.googleapis.com/storage/v1/b?project=" + PROJECT_ID;

  try {
    await request("POST", createUrl, token, {
      name: STORAGE_BUCKET,
      location: STORAGE_LOCATION,
      storageClass: "STANDARD",
    });
    console.log("Created bucket:", STORAGE_BUCKET);
  } catch (err) {
    if (String(err.message).includes("409") || String(err.message).includes("already exists")) {
      console.log("Bucket already exists:", STORAGE_BUCKET);
    } else {
      throw err;
    }
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
