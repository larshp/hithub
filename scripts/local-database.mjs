import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";

export async function createLocalDatabase(statements = []) {
  const database = new SQLiteDatabaseClient();
  await database.connect();
  if (statements.length > 0) {
    await database.execute(statements);
  }
  return database;
}
