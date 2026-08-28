import express from "express";
import {createHash} from "node:crypto";
import {readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {createLocalDatabase} from "../scripts/local-database.mjs";
import {initializeABAP} from "../build/transpiled/init.mjs";
import {cl_express_icf_shim} from "../build/transpiled/cl_express_icf_shim.clas.mjs";

await initializeABAP();
const generated = readFileSync(new URL("../build/transpiled/init.mjs", import.meta.url), "utf8");
const tick = String.fromCharCode(96);
const statements = generated.split("\n")
  .filter((line) => line.includes("sqlite.push("))
  .map((line) => line.slice(line.indexOf(tick) + 1, line.lastIndexOf(tick)));
const database = await createLocalDatabase(statements);
globalThis.abap.context.databaseConnections.DEFAULT = database;
const seedRepository = process.env.HITHUB_EMPTY_REPOSITORY;
if (seedRepository && /^[A-Za-z0-9._-]+$/.test(seedRepository)) {
  const escapedRepository = seedRepository.replaceAll("'", "''");
  await database.execute([`INSERT INTO zhi_repository
    (id, name, description, default_branch, version, deleted)
    VALUES ('seed-empty', '${escapedRepository}', '', 'main', 1, '')`]);
}
const fixtureRepository = process.env.HITHUB_FIXTURE_REPOSITORY;
if (fixtureRepository && /^[A-Za-z0-9._-]+$/.test(fixtureRepository)) {
  const repositoryId = "seed-branch";
  const object = (type, payload) => {
    const header = Buffer.from(`${type} ${payload.length}\0`);
    const oid = createHash("sha1").update(Buffer.concat([header, payload])).digest("hex");
    return {type, payload, oid};
  };
  const blobMain = object("blob", Buffer.from("hello\n"));
  const treeMain = object("tree", Buffer.concat([
    Buffer.from("100644 README\0"), Buffer.from(blobMain.oid, "hex"),
  ]));
  const commitMain = object("commit", Buffer.from(
    `tree ${treeMain.oid}\nauthor Alice <alice@example.com> 0 +0000\n` +
    `committer Alice <alice@example.com> 0 +0000\n\nmain\n`,
  ));
  const blobFeature = object("blob", Buffer.from("feature\n"));
  const treeFeature = object("tree", Buffer.concat([
    Buffer.from("100644 README\0"), Buffer.from(blobFeature.oid, "hex"),
  ]));
  const commitFeature = object("commit", Buffer.from(
    `tree ${treeFeature.oid}\nparent ${commitMain.oid}\n` +
    `author Alice <alice@example.com> 1 +0000\n` +
    `committer Alice <alice@example.com> 1 +0000\n\nfeature\n`,
  ));
  const tag = object("tag", Buffer.from(
    `object ${commitMain.oid}\ntype commit\ntag v1\n` +
    `tagger Alice <alice@example.com> 0 +0000\n\nv1\n`,
  ));
  const escapedFixture = fixtureRepository.replaceAll("'", "''");
  const objects = [blobMain, treeMain, commitMain, blobFeature, treeFeature, commitFeature, tag];
  const seedStatements = [
    `INSERT INTO zhi_repository (id, name, description, default_branch, version, deleted)
      VALUES ('${repositoryId}', '${escapedFixture}', 'fixture', 'main', 1, '')`,
    ...objects.map((item) => `INSERT INTO zhi_object
      (repository_id, algorithm, oid, object_type, object_size, payload)
      VALUES ('${repositoryId}', 'sha1', '${item.oid}', '${item.type}',
        ${item.payload.length}, '${item.payload.toString("hex")}')`),
    `INSERT INTO zhi_reference
      (repository_id, ref_name, algorithm, oid, symbolic_target, version)
      VALUES ('${repositoryId}', 'refs/heads/main', 'sha1', '${commitMain.oid}', '', 1)`,
    `INSERT INTO zhi_reference
      (repository_id, ref_name, algorithm, oid, symbolic_target, version)
      VALUES ('${repositoryId}', 'refs/heads/feature', 'sha1', '${commitFeature.oid}', '', 1)`,
    `INSERT INTO zhi_reference
      (repository_id, ref_name, algorithm, oid, symbolic_target, version)
      VALUES ('${repositoryId}', 'refs/tags/v1', 'sha1', '${tag.oid}', '', 1)`,
  ];
  await database.execute(seedStatements);
}

const app = express();
const port = Number(process.env.HITHUB_PORT || 3000);
const webRoot = fileURLToPath(new URL("../web", import.meta.url));
const configuredCorsOrigins = (process.env.HITHUB_CORS_ORIGIN || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);
const cookieAuthentication = process.env.HITHUB_COOKIE_AUTH === "true";
const csrfCookieName = process.env.HITHUB_CSRF_COOKIE || "hithub_csrf";
const requestBodyLimit = process.env.HITHUB_BODY_LIMIT || "64mb";
const rateLimit = Number(process.env.HITHUB_RATE_LIMIT || 300);
const rateWindowMs = Number(process.env.HITHUB_RATE_WINDOW_MS || 60000);
const requestCounts = new Map();
const contentSecurityPolicy = [
  "default-src 'self'",
  "base-uri 'self'",
  "connect-src 'self'",
  "font-src 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
  "img-src 'self' data:",
  "object-src 'none'",
  "script-src 'self'",
  "style-src 'self'",
].join("; ");

app.use((_req, res, next) => {
  res.setHeader("Content-Security-Policy", contentSecurityPolicy);
  next();
});

function cookieValue(request, name) {
  const cookies = request.get("cookie") || "";
  const escapedName = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = cookies.match(new RegExp(`(?:^|;\\s*)${escapedName}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : "";
}

app.use((req, res, next) => {
  const requestOrigin = req.get("origin");
  const allowed = configuredCorsOrigins.includes("*")
    ? "*"
    : configuredCorsOrigins.includes(requestOrigin)
      ? requestOrigin
      : "";
  if (allowed) {
    res.setHeader("Access-Control-Allow-Origin", allowed);
    res.setHeader("Vary", "Origin");
    res.setHeader(
      "Access-Control-Allow-Methods",
      "GET,POST,PATCH,DELETE,OPTIONS",
    );
    res.setHeader(
      "Access-Control-Allow-Headers",
      "Content-Type,If-Match,Idempotency-Key,X-Request-ID",
    );
  }
  if (req.method === "OPTIONS" && allowed) {
    res.status(204).end();
    return;
  }
  next();
});

app.use((req, res, next) => {
  if (!Number.isFinite(rateLimit) || rateLimit <= 0) {
    next();
    return;
  }
  const now = Date.now();
  const key = req.socket.remoteAddress || "unknown";
  const current = requestCounts.get(key);
  if (!current || now >= current.resetAt) {
    requestCounts.set(key, {count: 1, resetAt: now + rateWindowMs});
    next();
    return;
  }
  if (current.count >= rateLimit) {
    res.setHeader("Retry-After", String(Math.ceil((current.resetAt - now) / 1000)));
    res.status(429).type("application/problem+json").send(JSON.stringify({
      type: "https://hithub.invalid/problems/rate-limit",
      title: "Too Many Requests",
      status: 429,
      detail: "The request rate limit has been exceeded.",
      instance: req.path,
    }));
    return;
  }
  current.count += 1;
  next();
});

app.use((req, res, next) => {
  const stateChanging = ["POST", "PATCH", "PUT", "DELETE"].includes(req.method);
  if (!cookieAuthentication || !stateChanging || req.method === "OPTIONS") {
    next();
    return;
  }
  const cookieToken = cookieValue(req, csrfCookieName);
  const headerToken = req.get("x-csrf-token") || "";
  if (cookieToken && headerToken && cookieToken === headerToken) {
    next();
    return;
  }
  res.status(403).type("application/problem+json").send(JSON.stringify({
    type: "https://hithub.invalid/problems/csrf",
    title: "Forbidden",
    status: 403,
    detail: "A valid CSRF token is required for cookie-authenticated mutations.",
    instance: req.path,
  }));
});

app.use(express.raw({type: "*/*", limit: requestBodyLimit}));
app.use(express.static(webRoot, {index: "index.html"}));
app.get("/ui/*", (req, res) => {
  res.sendFile(`${webRoot}/index.html`);
});

app.all(["/health", "/health/*"], async (req, res) => {
  await cl_express_icf_shim.run({
    req,
    res,
    class: "ZCL_HITHUB_HTTP",
  });
});

app.all("*", async (req, res) => {
  await cl_express_icf_shim.run({
    req,
    res,
    class: "ZCL_HITHUB_HTTP",
  });
});

app.use((error, req, res, next) => {
  if (res.headersSent) {
    next(error);
    return;
  }
  const tooLarge = error?.type === "entity.too.large";
  const status = tooLarge ? 413 : 500;
  res.status(status).type("application/problem+json").send(JSON.stringify({
    type: tooLarge
      ? "https://hithub.invalid/problems/request-too-large"
      : "https://hithub.invalid/problems/internal-error",
    title: tooLarge ? "Payload Too Large" : "Internal Server Error",
    status,
    detail: tooLarge
      ? "The request body exceeds the configured request limit."
      : "The request could not be completed.",
    instance: req.path,
  }));
});

app.listen(port, "127.0.0.1", () => {
  console.log(`HitHub listening on http://127.0.0.1:${port}`);
});
