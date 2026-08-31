import {strict as assert} from "node:assert";
import {spawn} from "node:child_process";
import {createHash} from "node:crypto";
import {test} from "node:test";
import {fileURLToPath} from "node:url";

const repoRoot = fileURLToPath(new URL("../../", import.meta.url));

function createNativePack() {
  return new Promise((resolve, reject) => {
    const child = spawn("git", ["pack-objects", "--all", "--stdout"], {cwd: repoRoot});
    const chunks = [];
    let stderr = "";
    child.stdout.on("data", (chunk) => chunks.push(chunk));
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`git pack-objects failed: ${stderr}`));
      } else {
        resolve(Buffer.concat(chunks));
      }
    });
    child.stdin.end();
  });
}

test("native Git pack corpus has a valid v2 envelope", async () => {
  const pack = await createNativePack();
  assert.equal(pack.subarray(0, 4).toString("ascii"), "PACK");
  assert.equal(pack.readUInt32BE(4), 2);
  assert.ok(pack.readUInt32BE(8) > 0);
  assert.ok(pack.length > 32);

  const body = pack.subarray(0, -20);
  const trailer = pack.subarray(-20).toString("hex");
  assert.equal(createHash("sha1").update(body).digest("hex"), trailer);
});
