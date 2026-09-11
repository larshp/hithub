// The service worker the preview deployment is served through.
//
// GitHub Pages can only hand out files, and HitHub is an HTTP application, so
// the preview registers this worker and answers its own requests from it. The
// worker is to the browser what express is to the local server: it strips the
// mount path, forwards the request to the ABAP handler and turns the answer
// back into an HTTP response. Everything below /pr-<number>/ therefore behaves
// like a real deployment - the frontend is the unmodified SMIM bundle, the
// URLs are real URLs, and a reload lands on the same page.
//
// The listeners are registered during the initial evaluation of the script, as
// the service worker specification requires, and the application itself is
// imported on the first request: loading the ABAP runtime is the slow part and
// it must not delay activation.
import {sqliteSchema} from "./generated/sqlite-schema.mjs";

// Where the preview is deployed, e.g. "/hithub-preview-deployments/pr-42/".
// The ICF service node plays the same role on an installed system, and the
// frontend derives its base path from the URL exactly as it does there.
const MOUNT = new URL("./", self.location).pathname;
const DATABASE_CACHE = "hithub-preview-database";
const DATABASE_KEY = `${MOUNT}__preview/database`;
const RESET_PATH = "__preview/reset";
// Files the deployment serves itself. The worker's scope covers the whole
// preview directory, so the reports the workflow copies next to the
// application have to be handed back to the network.
const DEPLOYMENT_PATHS = ["sw.js", "screenshots/", "visual-diffs/"];
const EMPTY_STATUSES = new Set([204, 205, 304]);

let application;

self.addEventListener("install", () => {
  // A preview is disposable: there is no old version worth draining.
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin
      || !url.pathname.startsWith(MOUNT)) {
    return;
  }
  const path = url.pathname.slice(MOUNT.length);
  if (DEPLOYMENT_PATHS.some((prefix) => path === prefix
      || path.startsWith(prefix))) {
    return;
  }
  event.respondWith(serve(event.request, url, path));
});

async function serve(request, url, path) {
  try {
    const backend = await start();
    if (path === RESET_PATH) {
      await backend.resetBackend();
      await storeDatabase(backend);
      return Response.redirect(MOUNT, 303);
    }
    const mutation = request.method !== "GET" && request.method !== "HEAD";
    const answer = await backend.handleRequest({
      method: request.method,
      path: `/${path}`,
      search: url.search,
      headers: Object.fromEntries(request.headers),
      body: mutation
        ? new Uint8Array(await request.arrayBuffer())
        : undefined,
    });
    if (mutation) {
      await storeDatabase(backend);
    }
    return new Response(
      EMPTY_STATUSES.has(answer.status) ? null : answer.body,
      {status: answer.status, headers: answer.headers},
    );
  } catch (error) {
    return failure(error);
  }
}

function start() {
  application ??= load().catch((error) => {
    // A failed boot must not be cached, or the preview stays broken until the
    // worker is terminated.
    application = undefined;
    throw error;
  });
  return application;
}

async function load() {
  const backend = await import("./preview-backend.mjs");
  const stored = await readDatabase();
  await backend.startBackend(stored);
  if (stored === undefined) {
    await storeDatabase(backend);
  }
  return backend;
}

// The worker is shut down whenever it goes idle, which would throw away
// everything a visitor has created in the preview. Keep the database in the
// cache storage so the next start reads it back. The schema is part of the
// stored entry: a deployment that changes the tables has to start over rather
// than open a database the application no longer fits.
async function schemaDigest() {
  const source = new TextEncoder().encode(sqliteSchema.join("\n"));
  const digest = await crypto.subtle.digest("SHA-256", source);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function readDatabase() {
  try {
    const cache = await caches.open(DATABASE_CACHE);
    const stored = await cache.match(DATABASE_KEY);
    if (stored === undefined
        || stored.headers.get("x-schema-digest") !== await schemaDigest()) {
      return undefined;
    }
    return new Uint8Array(await stored.arrayBuffer());
  } catch (_error) {
    // Storage can be unavailable, for instance in a private window. The
    // preview then starts from the seeded content on every load, which is
    // worse than remembering but better than not answering at all.
    return undefined;
  }
}

async function storeDatabase(backend) {
  try {
    const cache = await caches.open(DATABASE_CACHE);
    await cache.put(DATABASE_KEY, new Response(await backend.exportDatabase(), {
      headers: {
        "content-type": "application/octet-stream",
        "x-schema-digest": await schemaDigest(),
      },
    }));
  } catch (_error) {
    // See readDatabase: losing the write costs the visitor their edits after
    // the worker restarts, and nothing else.
  }
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function failure(error) {
  const message = escapeHtml(error?.stack || error?.message || error);
  return new Response(`<!doctype html>
<meta charset="utf-8">
<title>Preview failed</title>
<style>body{margin:0;padding:2rem;font:16px system-ui,sans-serif;color:#e6edf3;background:#0d1117}
h1{font-size:1.4rem}pre{overflow:auto;padding:1rem;border-radius:6px;background:#161b22;white-space:pre-wrap}
a{color:#4493f8}</style>
<h1>The preview could not answer this request</h1>
<pre>${message}</pre>
<p><a href="${MOUNT}${RESET_PATH}">Reset the preview</a></p>
`, {status: 500, headers: {"content-type": "text/html; charset=utf-8"}});
}
