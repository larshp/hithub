import { SQLiteDatabaseClient } from "@abaplint/database-sqlite";

export async function initializeDatabase(abap, schemas, insert) {
  const database = new SQLiteDatabaseClient();
  abap.context.databaseConnections.DEFAULT = database;
  await database.connect();
  await database.execute(schemas.sqlite);
  await database.execute(`CREATE TABLE "zabapgit" (
    "type" NCHAR(20),
    "value" NCHAR(255),
    "data_str" TEXT,
    PRIMARY KEY ("type", "value")
  );`);
  await database.execute(insert);
}
