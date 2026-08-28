import {readFileSync} from "node:fs";
import {createLocalDatabase} from "./local-database.mjs";

const generated = readFileSync("build/transpiled/init.mjs", "utf8");
const tick = String.fromCharCode(96);
const statements = generated.split("\n")
  .filter((line) => line.includes("sqlite.push("))
  .map((line) => line.slice(line.indexOf(tick) + 1, line.lastIndexOf(tick)));

await import("../build/transpiled/init.mjs");
const database = await createLocalDatabase(statements);
globalThis.abap.context.databaseConnections.DEFAULT = database;
await import("../build/transpiled/index.mjs");
