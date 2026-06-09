/**
 * Seeds config/daily_verse using Firebase CLI login credentials (Spark plan OK).
 * Run: node scripts/seed-config.js
 */
const fs = require("fs");
const path = require("path");
const https = require("https");

const PROJECT_ID = "scripture-memorizer-app";
const CLIENT_ID =
  "563584335869-fgrhgmd47bqnekij5i8b5k7a1ga876b.apps.googleusercontent.com";
const CLIENT_SECRET = "j9pD0C5bdTO11uCkNLAXyKqDuNk";

function loadRefreshToken() {
  const candidates = [
    path.join(process.env.APPDATA || "", "configstore", "firebase-tools.json"),
    path.join(
      process.env.USERPROFILE || process.env.HOME || "",
      ".config",
      "configstore",
      "firebase-tools.json",
    ),
  ];
  for (const file of candidates) {
    if (fs.existsSync(file)) {
      const data = JSON.parse(fs.readFileSync(file, "utf8"));
      const token = data?.tokens?.refresh_token;
      if (token) return token;
    }
  }
  throw new Error("Run `firebase login` first.");
}

function postForm(url, body) {
  return new Promise((resolve, reject) => {
    const data = new URLSearchParams(body).toString();
    const req = https.request(
      url,
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          try {
            resolve(JSON.parse(raw));
          } catch (e) {
            reject(new Error(raw || String(res.statusCode)));
          }
        });
      },
    );
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

function patchJson(url, token, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = https.request(
      url,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(data),
        },
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(raw ? JSON.parse(raw) : {});
            return;
          }
          reject(new Error(`Firestore ${res.statusCode}: ${raw}`));
        });
      },
    );
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

function toFirestoreValue(value) {
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((v) => toFirestoreValue(v)),
      },
    };
  }
  throw new Error(`Unsupported type: ${typeof value}`);
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    fields[key] = toFirestoreValue(value);
  }
  return fields;
}

async function main() {
  const configPath = path.join(__dirname, "..", "seed", "config.daily_verse.json");
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const refreshToken = loadRefreshToken();

  const tokenResponse = await postForm("https://oauth2.googleapis.com/token", {
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: refreshToken,
    grant_type: "refresh_token",
  });

  if (!tokenResponse.access_token) {
    throw new Error("Could not refresh access token. Run `firebase login` again.");
  }

  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    "/databases/(default)/documents/config/daily_verse";

  await patchJson(url, tokenResponse.access_token, {
    fields: toFirestoreFields(config),
  });

  console.log("Seeded config/daily_verse successfully.");
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
