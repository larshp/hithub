import express from "express";
import {createHash} from "node:crypto";
import {readFileSync} from "node:fs";
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

app.use(express.raw({type: "*/*"}));

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

app.listen(port, "127.0.0.1", () => {
  console.log(`HitHub listening on http://127.0.0.1:${port}`);
});
