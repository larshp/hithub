import {createHash} from "node:crypto";

function objectId(type, payload) {
  const bytes = Buffer.from(payload, "utf8");
  const header = Buffer.from(`${type} ${bytes.length}\0`, "utf8");
  return createHash("sha1").update(Buffer.concat([header, bytes])).digest("hex");
}

export function repositoryFixture(overrides = {}) {
  return {
    id: "repo-fixture-000000000000000000000000000000",
    name: "fixture-repository",
    description: "Deterministic HitHub persistence fixture",
    defaultBranch: "refs/heads/main",
    version: 1,
    deleted: false,
    ...overrides,
  };
}

export function commitFixture(overrides = {}) {
  const tree = overrides.tree ?? "1111111111111111111111111111111111111111";
  const parent = overrides.parent;
  const author = overrides.author ?? "Fixture Author <fixture@example.invalid>";
  const committer = overrides.committer ?? author;
  const timestamp = overrides.timestamp ?? "1704067200 +0000";
  const message = overrides.message ?? "Fixture commit\n";
  const lines = [`tree ${tree}`];
  if (parent) lines.push(`parent ${parent}`);
  lines.push(`author ${author} ${timestamp}`);
  lines.push(`committer ${committer} ${timestamp}`);
  lines.push("", message);
  const payload = lines.join("\n");

  return {
    type: "commit",
    algorithm: "sha1",
    oid: objectId("commit", payload),
    size: Buffer.byteLength(payload),
    payload,
  };
}

export function refFixture(overrides = {}) {
  const commit = overrides.commit ?? commitFixture();
  return {
    repositoryId: "repo-fixture-000000000000000000000000000000",
    name: "refs/heads/main",
    algorithm: "sha1",
    oid: commit.oid,
    symbolicTarget: "",
    version: 1,
    ...overrides,
  };
}
