import {readFileSync} from "node:fs";
import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";

const generated = readFileSync("build/transpiled/init.mjs", "utf8");
const tick = String.fromCharCode(96);
const statements = generated.split("\n")
  .filter((line) => line.includes("sqlite.push("))
  .map((line) => line.slice(line.indexOf(tick) + 1, line.lastIndexOf(tick)));

await import("../build/transpiled/init.mjs");
const database = new SQLiteDatabaseClient();
await database.connect();
await database.execute(statements);
globalThis.abap.context.databaseConnections.DEFAULT = database;
await import("../build/transpiled/index.mjs");
