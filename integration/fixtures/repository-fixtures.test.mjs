import {strict as assert} from "node:assert";
import {test} from "node:test";
import {createHash} from "node:crypto";
import {commitFixture, refFixture, repositoryFixture} from "./repository-fixtures.mjs";

test("repository fixture has stable metadata", () => {
  assert.deepEqual(repositoryFixture(), {
    id: "repo-fixture-000000000000000000000000000000",
    name: "fixture-repository",
    description: "Deterministic HitHub persistence fixture",
    defaultBranch: "refs/heads/main",
    version: 1,
    deleted: false,
  });
});

test("commit fixture uses the canonical Git object hash", () => {
  const fixture = commitFixture();
  const bytes = Buffer.from(fixture.payload, "utf8");
  const header = Buffer.from(`commit ${bytes.length}\0`, "utf8");
  const expected = createHash("sha1").update(Buffer.concat([header, bytes])).digest("hex");
  assert.equal(fixture.size, bytes.length);
  assert.equal(fixture.oid, expected);
});

test("ref fixture points to its commit fixture", () => {
  const commit = commitFixture({message: "Ref target\n"});
  const ref = refFixture({commit});
  assert.equal(ref.oid, commit.oid);
  assert.equal(ref.name, "refs/heads/main");
  assert.equal(ref.algorithm, "sha1");
});
