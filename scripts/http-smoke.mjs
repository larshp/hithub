import {spawn} from "node:child_process";

const port = 3100;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

try {
  let response;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      response = await fetch(`http://127.0.0.1:${port}/health`);
      break;
    } catch (_error) {
      await wait(100);
    }
  }
  if (!response || !response.ok) {
    throw new Error("HTTP smoke test could not reach /health");
  }
  const body = await response.json();
  if (body.status !== "ok" || body.runtime !== "abap") {
    throw new Error("HTTP smoke test received an invalid /health response");
  }
  const createResponse = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      name: "smoke-repository",
      description: "HTTP smoke fixture",
      default_branch: "main",
    }),
  });
  if (createResponse.status !== 201) {
    throw new Error(`HTTP smoke create failed: ${createResponse.status}`);
  }
  const created = await createResponse.json();
  if (created.name !== "smoke-repository"
      || created.default_branch !== "refs/heads/main"
      || !created.id) {
    throw new Error("HTTP smoke create returned an invalid repository");
  }
  const listResponse = await fetch(`http://127.0.0.1:${port}/api/repos`);
  if (!listResponse.ok) {
    throw new Error(`HTTP smoke list failed: ${listResponse.status}`);
  }
  const listed = await listResponse.json();
  if (!Array.isArray(listed)
      || !listed.some((item) => item.name === "smoke-repository")) {
    throw new Error("HTTP smoke list omitted the created repository");
  }
  const retrieveResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/SMOKE-REPOSITORY`,
  );
  if (!retrieveResponse.ok) {
    throw new Error(`HTTP smoke retrieve failed: ${retrieveResponse.status}`);
  }
  const retrieved = await retrieveResponse.json();
  if (retrieved.id !== created.id || retrieved.name !== "smoke-repository") {
    throw new Error("HTTP smoke retrieve returned an invalid repository");
  }
  const updateResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({description: "Updated by HTTP smoke"}),
    },
  );
  if (!updateResponse.ok) {
    throw new Error(`HTTP smoke update failed: ${updateResponse.status}`);
  }
  const updated = await updateResponse.json();
  if (updated.description !== "Updated by HTTP smoke" || updated.version !== 2) {
    throw new Error("HTTP smoke update returned an invalid repository");
  }
  const staleUpdateResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({description: "Stale update"}),
    },
  );
  if (staleUpdateResponse.status !== 412) {
    throw new Error("HTTP smoke stale update was not rejected");
  }
  const duplicateResponse = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "SMOKE-REPOSITORY"}),
  });
  if (duplicateResponse.status !== 409
      || !duplicateResponse.headers.get("content-type")?.includes(
        "application/problem+json")) {
    throw new Error("HTTP smoke duplicate create was not rejected as a conflict");
  }
  const deleteResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository`,
    {
      method: "DELETE",
      headers: {"if-match": '"2"'},
    },
  );
  if (deleteResponse.status !== 204) {
    throw new Error(`HTTP smoke delete failed: ${deleteResponse.status}`);
  }
  const deletedRetrieveResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository`,
  );
  if (deletedRetrieveResponse.status !== 404) {
    throw new Error("HTTP smoke deleted repository remained visible");
  }
  console.log("HTTP smoke test passed");
} finally {
  child.kill("SIGTERM");
}
