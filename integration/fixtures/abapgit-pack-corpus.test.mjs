import {strict as assert} from "node:assert";
import {createHash} from "node:crypto";
import {inflateSync} from "node:zlib";
import {test} from "node:test";
import {abapGitPackCorpus} from "./abapgit-pack-corpus.mjs";

test("abapGit pack corpus preserves envelope and object identity", () => {
  for (const fixture of abapGitPackCorpus) {
    const pack = Buffer.from(fixture.packHex, "hex");
    const body = pack.subarray(0, -20);
    const entry = body.subarray(12);
    const compressed = entry.subarray(1);
    const raw = inflateSync(compressed);
    const header = Buffer.from(`${fixture.objectType} ${fixture.objectPayload.length}\0`, "utf8");

    assert.equal(pack.subarray(0, 4).toString("ascii"), "PACK", fixture.name);
    assert.equal(pack.readUInt32BE(4), 2, fixture.name);
    assert.equal(pack.readUInt32BE(8), 1, fixture.name);
    assert.equal(createHash("sha1").update(body).digest("hex"), pack.subarray(-20).toString("hex"), fixture.name);
    assert.deepEqual(raw, Buffer.concat([header, fixture.objectPayload]), fixture.name);
    assert.equal(createHash("sha1").update(raw).digest("hex"), fixture.objectId, fixture.name);
  }
});
