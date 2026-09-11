import {strict as assert} from "node:assert";
import {spawn} from "node:child_process";
import {test} from "node:test";
import {createHash} from "node:crypto";
import {nativeGitGoldenFixtures} from "./native-git-golden.mjs";

function nativeGitHash(type, payload) {
  return new Promise((resolve, reject) => {
    const child = spawn("git", ["hash-object", "--stdin", "-t", type]);
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`git hash-object failed: ${stderr}`));
      } else {
        resolve(stdout.trim());
      }
    });
    child.stdin.end(payload);
  });
}

test("native Git golden fixtures preserve canonical bytes and IDs", async () => {
  for (const fixture of nativeGitGoldenFixtures) {
    const header = Buffer.from(`${fixture.type} ${fixture.payload.length}\0`, "utf8");
    const canonical = Buffer.concat([header, fixture.payload]);
    const expectedByHash = createHash("sha1").update(canonical).digest("hex");

    assert.equal(header.toString("hex"), fixture.headerHex, fixture.name);
    assert.equal(expectedByHash, fixture.oid, fixture.name);
    assert.equal(await nativeGitHash(fixture.type, fixture.payload), fixture.oid, fixture.name);
  }
});
