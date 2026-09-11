// The HitHub backend, running in the browser.
//
// server/index.mjs wires the transpiled ABAP application into express for local
// development: it opens a SQLite database, points the persistence layer at the
// open-abap adapters, hands the serialized SMIM assets to the local asset store
// and then forwards every express request into ZCL_HITHUB_HTTP through the ICF
// shim. This module does exactly the same for the preview deployment, with the
// service worker in the role of express and sql.js compiled to JavaScript in
// the role of the database file.
//
// The environment the generated runtime expects is prepared first, before that
// runtime is imported.
import "./preview-runtime.mjs";
import {Buffer} from "buffer";
import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";
import {initializeABAP} from "../output/init.mjs";
import {cl_express_icf_shim} from "../output/cl_express_icf_shim.clas.mjs";
import {zcl_hithub_persistence} from "../output/zcl_hithub_persistence.clas.mjs";
import {
  zcl_hithub_local_asset_store,
} from "../output/zcl_hithub_local_asset_store.clas.mjs";
import {frontendAssets} from "./generated/frontend-assets.mjs";
import {sqliteSchema} from "./generated/sqlite-schema.mjs";
import {seedPreviewContent} from "./preview-seed.mjs";

// CL_EXPRESS_ICF_SHIM keeps the request and the response on one static server
// object, so two overlapping calls would answer each other's requests. Node
// gets away with it because one express handler rarely awaits another; the
// browser hands out fetch events as fast as the page asks for them. Serialize
// them instead.
let queue = Promise.resolve();
let database;

function toBytes(value) {
  if (value instanceof Uint8Array) {
    return value;
  }
  if (value instanceof ArrayBuffer) {
    return new Uint8Array(value);
  }
  return new TextEncoder().encode(String(value ?? ""));
}

async function openDatabase(stored) {
  database = new SQLiteDatabaseClient();
  await database.connect(stored);
  if (stored === undefined) {
    await database.execute(sqliteSchema);
  }
  globalThis.abap.context.databaseConnections.DEFAULT = database;
  if (stored === undefined) {
    await seedPreviewContent(invoke);
  }
}

async function invoke({method, path, search = "", headers = {}, body}) {
  const responseHeaders = new Headers();
  let status = 200;
  let data = new Uint8Array(0);
  const response = {
    append(name, value) {
      responseHeaders.append(name, value);
    },
    status(code) {
      status = Number(code);
      return response;
    },
    send(payload) {
      data = toBytes(payload);
    },
  };

  await cl_express_icf_shim.run({
    req: {
      body: Buffer.from(body ?? new Uint8Array(0)),
      headers,
      method: String(method || "GET").toUpperCase(),
      path,
      url: `${path}${search}`,
    },
    res: response,
    class: "ZCL_HITHUB_HTTP",
  });

  return {status, headers: responseHeaders, body: data};
}

function serialized(work) {
  const result = queue.then(work, work);
  queue = result.then(() => undefined, () => undefined);
  return result;
}

export async function startBackend(stored) {
  await initializeABAP();
  // ZCL_HITHUB_PERSISTENCE defaults to the SAP adapters. Nothing here can
  // reach an application server, so opt out before the first request, as the
  // local server does.
  await zcl_hithub_persistence.use_open_abap();
  // An installed service reads the browser assets from the MIME repository.
  // Here they are compiled into the bundle from the same serialized SMIM files
  // abapGit installs, and handed to the local asset store instead.
  for (const asset of frontendAssets) {
    await zcl_hithub_local_asset_store.register({
      iv_name: asset.name,
      iv_mime_type: asset.mimeType,
      iv_content: asset.content,
    });
  }
  await openDatabase(stored);
}

// Answer one request from the application. Returns the status, headers and
// body rather than a Response so the caller decides what a response looks like.
export function handleRequest(request) {
  return serialized(() => invoke(request));
}

// Throw the preview away and seed it again, so a visitor who has edited the
// data can get back to the state the screenshots were taken in.
export function resetBackend() {
  return serialized(() => openDatabase(undefined));
}

export function exportDatabase() {
  return serialized(() => database.export());
}
