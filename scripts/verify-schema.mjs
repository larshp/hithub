import {readFileSync} from "node:fs";
import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";

const expected = {
  zhi_repository: {
    columns: {
      id: "NCHAR(36)", name: "NCHAR(100)", description: "NCHAR(255)",
      default_branch: "NCHAR(100)", version: "INT", deleted: "NCHAR(1)",
    },
    primaryKey: ["id", "name"],
  },
  zhi_reference: {
    columns: {
      repository_id: "NCHAR(36)", ref_name: "NCHAR(160)", algorithm: "NCHAR(16)",
      oid: "NCHAR(64)", symbolic_target: "NCHAR(160)", version: "INT",
    },
    primaryKey: ["repository_id", "ref_name"],
  },
  zhi_object: {
    columns: {
      repository_id: "NCHAR(36)", algorithm: "NCHAR(16)", oid: "NCHAR(64)",
      object_type: "NCHAR(6)", object_size: "INT", payload: "NCHAR(64000)",
    },
    primaryKey: ["repository_id", "algorithm", "oid"],
  },
  zhi_event: {
    columns: {
      event_id: "NCHAR(36)", actor: "NCHAR(100)", action: "NCHAR(100)",
      subject_type: "NCHAR(32)", subject_id: "NCHAR(100)",
      correlation_id: "NCHAR(36)", occurred_at: "NCHAR(27)", details: "NCHAR(32000)",
    },
    primaryKey: ["event_id"],
  },
};

const generated = readFileSync("build/transpiled/init.mjs", "utf8");
const statements = [...generated.matchAll(/sqlite\.push\(`(CREATE TABLE [^`]+)`\);/g)]
  .map((match) => match[1]);
const schemaStatements = statements.filter((statement) =>
  Object.keys(expected).some((table) => statement.includes(`'${table}'`)));

if (schemaStatements.length !== Object.keys(expected).length) {
  throw new Error("Generated init.mjs does not contain every HitHub metadata table");
}

globalThis.abap = {context: {databaseConnections: {}}};
const database = new SQLiteDatabaseClient();
await database.connect();
await database.execute(schemaStatements);

for (const [table, definition] of Object.entries(expected)) {
  const rows = (await database.select({select: `PRAGMA table_info('${table}')`})).rows;
  const actualColumns = Object.fromEntries(rows.map((row) => [row.name, row.type]));
  if (JSON.stringify(actualColumns) !== JSON.stringify(definition.columns)) {
    throw new Error(`Column definition mismatch for ${table}`);
  }

  const actualKey = rows.filter((row) => row.pk > 0)
    .sort((left, right) => left.pk - right.pk)
    .map((row) => row.name);
  if (JSON.stringify(actualKey) !== JSON.stringify(definition.primaryKey)) {
    throw new Error(`Primary-key definition mismatch for ${table}`);
  }

  const keyColumns = definition.primaryKey.map((column) => `"${column}"`).join(", ");
  const keyValues = definition.primaryKey.map((_, index) => `'schema-${index}'`).join(", ");
  const insert = `INSERT INTO "${table}" (${keyColumns}) VALUES (${keyValues});`;
  await database.execute(insert);
  let rejected = false;
  try {
    await database.execute(insert);
  } catch (_error) {
    rejected = true;
  }
  if (!rejected) {
    throw new Error(`Duplicate primary key was accepted by ${table}`);
  }
}

await database.disconnect();
console.log(`Local DDIC schema verified: ${Object.keys(expected).length} tables, columns, and primary keys`);
