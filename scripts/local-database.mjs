import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";

// initializeABAP() builds the DDL for every database the transpiler supports
// and then drops it on the floor, so the generated source is the only place
// the schema is written down. Both the local server and the browser preview
// read it back out of there before they open a database.
export function sqliteSchemaStatements(generated) {
  const tick = "`";
  const statements = generated.split("\n")
    .filter((line) => line.includes("sqlite.push("))
    .map((line) => line.slice(line.indexOf(tick) + 1, line.lastIndexOf(tick)));
  if (statements.length === 0) {
    throw new Error("The generated runtime declares no SQLite schema");
  }
  return statements;
}

export async function createLocalDatabase(statements = []) {
  const database = new SQLiteDatabaseClient();
  await database.connect();
  if (statements.length > 0) {
    await database.execute(statements);
  }
  return database;
}
