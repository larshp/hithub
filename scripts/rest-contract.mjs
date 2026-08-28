import {readFileSync} from "node:fs";
import {spawn} from "node:child_process";

const port = 3200;
const contract = readFileSync("docs/openapi.yaml", "utf8");
const operations = [
  ["/api/repos", "get", "listRepositories"],
  ["/api/repos", "post", "createRepository"],
  ["/api/repos/{repo}", "get", "getRepository"],
  ["/api/repos/{repo}", "patch", "updateRepository"],
  ["/api/repos/{repo}", "delete", "softDeleteRepository"],
  ["/api/repos/{repo}/purge", "post", "purgeRepository"],
  ["/api/repos/{repo}/branches", "get", "listBranches"],
  ["/api/repos/{repo}/branches", "post", "createBranch"],
  ["/api/repos/{repo}/branches/{branch}", "get", "getBranch"],
  ["/api/repos/{repo}/branches/{branch}", "patch", "updateBranch"],
  ["/api/repos/{repo}/branches/{branch}", "delete", "deleteBranch"],
  ["/api/repos/{repo}/tags", "get", "listTags"],
  ["/api/repos/{repo}/tags", "post", "createTag"],
  ["/api/repos/{repo}/tags/{tag}", "get", "getTag"],
  ["/api/repos/{repo}/tags/{tag}", "patch", "updateTag"],
  ["/api/repos/{repo}/tags/{tag}", "delete", "deleteTag"],
];

function fail(message) {
  throw new Error(`REST contract: ${message}`);
}

for (const [path, method, operationId] of operations) {
  const pathOffset = contract.indexOf(`  ${path}:`);
  if (pathOffset < 0) fail(`missing path ${path}`);
  const operationOffset = contract.indexOf(`    ${method}:`, pathOffset);
  if (operationOffset < 0) fail(`missing ${method.toUpperCase()} ${path}`);
  const nextPath = contract.indexOf("\n  /", pathOffset + 3);
  const operation = contract.slice(operationOffset, nextPath < 0 ? undefined : nextPath);
  if (!operation.includes(`operationId: ${operationId}`)) {
    fail(`missing operationId ${operationId}`);
  }
}

function assertRepository(value) {
  if (!value || typeof value.id !== "string" || typeof value.name !== "string"
      || typeof value.description !== "string"
      || typeof value.default_branch !== "string"
      || !Number.isInteger(value.version)) {
    fail("repository response did not match the Repository schema");
  }
}

function assertReference(value, prefix) {
  if (!value || typeof value.name !== "string"
      || !value.name.startsWith(prefix)
      || value.algorithm !== "sha1" || typeof value.oid !== "string"
      || !/^[0-9a-f]{40}$/i.test(value.oid)
      || !Number.isInteger(value.version)) {
    fail("reference response did not match the Reference schema");
  }
}

const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});

async function request(path, options) {
  const response = await fetch(`http://127.0.0.1:${port}${path}`, options);
  let body = null;
  if (response.status !== 204) body = await response.json();
  return {response, body};
}

try {
  let healthy = false;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      healthy = (await fetch(`http://127.0.0.1:${port}/health`)).ok;
      if (healthy) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!healthy) fail("server did not start");

  const created = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "contract-repository"}),
  });
  if (created.response.status !== 201) fail(`create returned ${created.response.status}`);
  assertRepository(created.body);

  const listed = await request("/api/repos");
  if (listed.response.status !== 200 || !Array.isArray(listed.body)) {
    fail("repository list did not return an array");
  }
  listed.body.forEach(assertRepository);

  const retrieved = await request("/api/repos/contract-repository");
  if (retrieved.response.status !== 200) fail("repository retrieve failed");
  assertRepository(retrieved.body);

  const retryFirst = await request("/api/repos", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "idempotency-key": "contract-retry",
    },
    body: JSON.stringify({name: "retry-repository"}),
  });
  const retrySecond = await request("/api/repos", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "idempotency-key": "contract-retry",
    },
    body: JSON.stringify({name: "retry-repository"}),
  });
  if (retryFirst.response.status !== 201 || retrySecond.response.status !== 201
      || retryFirst.body?.id !== retrySecond.body?.id) {
    fail("idempotent repository retry did not replay the original result");
  }

  const branch = await request("/api/repos/contract-repository/branches", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      name: "contract",
      oid: "1111111111111111111111111111111111111111",
    }),
  });
  if (branch.response.status !== 201) fail("branch create failed");
  assertReference(branch.body, "refs/heads/");

  const tag = await request("/api/repos/contract-repository/tags", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      name: "contract",
      oid: "2222222222222222222222222222222222222222",
    }),
  });
  if (tag.response.status !== 201) fail("tag create failed");
  assertReference(tag.body, "refs/tags/");

  const duplicate = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "CONTRACT-REPOSITORY"}),
  });
  if (duplicate.response.status !== 409
      || duplicate.response.headers.get("content-type")
        ?.includes("application/problem+json") !== true
      || duplicate.body?.status !== 409) {
    fail("problem response did not match the documented Conflict response");
  }
  const invalid = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({description: "missing name"}),
  });
  if (invalid.response.status !== 400 || invalid.body?.status !== 400) {
    fail("invalid create did not match the documented BadRequest response");
  }
  const missingPrecondition = await request(
    "/api/repos/contract-repository",
    {
      method: "PATCH",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({description: "missing If-Match"}),
    },
  );
  if (missingPrecondition.response.status !== 428
      || missingPrecondition.body?.status !== 428) {
    fail("missing If-Match did not match the documented precondition response");
  }
  const firstUpdate = await request(
    "/api/repos/contract-repository",
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({description: "first writer"}),
    },
  );
  if (firstUpdate.response.status !== 200 || firstUpdate.body?.version !== 2) {
    fail("first concurrent update did not succeed");
  }
  const staleUpdate = await request(
    "/api/repos/contract-repository",
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({description: "stale writer"}),
    },
  );
  if (staleUpdate.response.status !== 412 || staleUpdate.body?.status !== 412) {
    fail("stale concurrent update did not match the documented response");
  }
  console.log("REST contract test passed");
} finally {
  child.kill("SIGTERM");
}
