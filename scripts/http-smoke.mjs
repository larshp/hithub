import {spawn} from "node:child_process";

const port = 3100;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {
    ...process.env,
    HITHUB_PORT: String(port),
    HITHUB_CORS_ORIGIN: "http://localhost:4000",
  },
  stdio: "inherit",
});

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

try {
  let response;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      response = await fetch(`http://127.0.0.1:${port}/health`, {
        headers: {origin: "http://localhost:4000"},
      });
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
  if (response.headers.get("access-control-allow-origin")
      !== "http://localhost:4000") {
    throw new Error("HTTP smoke CORS response omitted the configured origin");
  }
  const preflightResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos`,
    {
      method: "OPTIONS",
      headers: {
        origin: "http://localhost:4000",
        "access-control-request-method": "POST",
      },
    },
  );
  if (preflightResponse.status !== 204
      || preflightResponse.headers.get("access-control-allow-origin")
        !== "http://localhost:4000") {
    throw new Error("HTTP smoke CORS preflight failed");
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
  if (retrieved.id !== created.id
      || retrieved.name !== "smoke-repository"
      || retrieved.readme !== "# smoke-repository\n") {
    throw new Error("HTTP smoke retrieve returned an invalid repository");
  }
  const initialBranchesResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/branches`,
  );
  const initialBranches = await initialBranchesResponse.json();
  if (initialBranchesResponse.status !== 200
      || !initialBranches.some((item) => item.name === "refs/heads/main")) {
    throw new Error("HTTP smoke create omitted the initial branch");
  }
  const contentsResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/contents/?ref=main`,
  );
  if (!contentsResponse.ok) {
    throw new Error(`HTTP smoke contents lookup failed: ${contentsResponse.status}`);
  }
  const contents = await contentsResponse.json();
  if (!Array.isArray(contents.entries)
      || !contents.entries.some((entry) => entry.name === "README.md")) {
    throw new Error("HTTP smoke contents omitted README.md");
  }
  const rawReadmeResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/contents/README.md?ref=main&format=raw`,
  );
  if (!rawReadmeResponse.ok
      || await rawReadmeResponse.text() !== "# smoke-repository\n") {
    throw new Error("HTTP smoke raw README lookup failed");
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
  const branchCreateResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/branches`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        name: "feature/smoke",
        oid: "1111111111111111111111111111111111111111",
      }),
    },
  );
  if (branchCreateResponse.status !== 201) {
    throw new Error(`HTTP smoke branch create failed: ${branchCreateResponse.status}`);
  }
  const branchCreated = await branchCreateResponse.json();
  if (branchCreated.name !== "refs/heads/feature/smoke"
      || branchCreated.version !== 1) {
    throw new Error("HTTP smoke branch create returned an invalid branch");
  }
  const branchListResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/branches`,
  );
  const branches = await branchListResponse.json();
  if (branchListResponse.status !== 200
      || !branches.some((item) => item.name === "refs/heads/feature/smoke")) {
    throw new Error("HTTP smoke branch list omitted the created branch");
  }
  const branchRetrieveResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/branches/feature/smoke`,
  );
  if (branchRetrieveResponse.status !== 200) {
    throw new Error("HTTP smoke branch retrieve failed");
  }
  const branchUpdateResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/branches/feature/smoke`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({
        oid: "2222222222222222222222222222222222222222",
      }),
    },
  );
  if (branchUpdateResponse.status !== 200
      || (await branchUpdateResponse.json()).version !== 2) {
    throw new Error("HTTP smoke branch update failed");
  }
  const branchDeleteResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/branches/feature/smoke`,
    {
      method: "DELETE",
      headers: {"if-match": '"2"'},
    },
  );
  if (branchDeleteResponse.status !== 204) {
    throw new Error("HTTP smoke branch delete failed");
  }
  const tagCreateResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/tags`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        name: "release/v1",
        oid: "3333333333333333333333333333333333333333",
      }),
    },
  );
  if (tagCreateResponse.status !== 201) {
    throw new Error(`HTTP smoke tag create failed: ${tagCreateResponse.status}`);
  }
  const tagCreated = await tagCreateResponse.json();
  if (tagCreated.name !== "refs/tags/release/v1"
      || tagCreated.version !== 1) {
    throw new Error("HTTP smoke tag create returned an invalid tag");
  }
  const tagListResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/tags`,
  );
  const tags = await tagListResponse.json();
  if (tagListResponse.status !== 200
      || !tags.some((item) => item.name === "refs/tags/release/v1")) {
    throw new Error("HTTP smoke tag list omitted the created tag");
  }
  const tagRetrieveResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/tags/release/v1`,
  );
  if (tagRetrieveResponse.status !== 200) {
    throw new Error("HTTP smoke tag retrieve failed");
  }
  const tagUpdateResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/tags/release/v1`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({
        oid: "4444444444444444444444444444444444444444",
      }),
    },
  );
  if (tagUpdateResponse.status !== 200
      || (await tagUpdateResponse.json()).version !== 2) {
    throw new Error("HTTP smoke tag update failed");
  }
  const tagDeleteResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/tags/release/v1`,
    {
      method: "DELETE",
      headers: {"if-match": '"2"'},
    },
  );
  if (tagDeleteResponse.status !== 204) {
    throw new Error("HTTP smoke tag delete failed");
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
  const purgeResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository/purge`,
    {
      method: "POST",
      headers: {"if-match": '"3"'},
    },
  );
  if (purgeResponse.status !== 204) {
    throw new Error(`HTTP smoke purge failed: ${purgeResponse.status}`);
  }
  const deletedRetrieveResponse = await fetch(
    `http://127.0.0.1:${port}/api/repos/smoke-repository`,
  );
  if (deletedRetrieveResponse.status !== 404) {
    throw new Error("HTTP smoke deleted repository remained visible");
  }
  const recreateResponse = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "smoke-repository"}),
  });
  if (recreateResponse.status !== 201) {
    throw new Error("HTTP smoke purge did not release the repository name");
  }
  console.log("HTTP smoke test passed");
} finally {
  child.kill("SIGTERM");
}
