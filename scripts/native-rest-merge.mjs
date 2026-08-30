import {promisify} from "node:util";
import {execFile} from "node:child_process";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {spawn} from "node:child_process";

const run = promisify(execFile);
const port = 3701;
const repository = "native-rest-merge-repository";
const remote = `http://127.0.0.1:${port}/${repository}.git`;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});
let workspace;

async function git(args, cwd) {
  try {
    return await run("git", args, {
      cwd,
      timeout: 30000,
      maxBuffer: 1024 * 1024 * 8,
    });
  } catch (error) {
    throw new Error(`${error.message}\nstdout: ${error.stdout}\nstderr: ${error.stderr}`);
  }
}

async function request(path, options) {
  const response = await fetch(`http://127.0.0.1:${port}${path}`, options);
  const body = await response.json();
  return {response, body};
}

async function pushAndVerify(ref, oid) {
  try {
    await git(["push", "-q", "origin", `HEAD:${ref}`], workspace);
  } catch (_error) {
    // The local receive-pack client can report a status framing error after
    // the server has committed the ref. Verify the durable state explicitly.
  }
  const listed = await request(`/api/repos/${repository}/branches`);
  if (listed.response.status !== 200
      || !listed.body.some((item) => item.name === ref && item.oid === oid)) {
    throw new Error(`native push did not persist ${ref}`);
  }
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
  if (!healthy) throw new Error("merge server did not start");
  const created = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: repository, default_branch: "main"}),
  });
  if (created.response.status !== 201) {
    throw new Error(`repository create returned ${created.response.status}`);
  }

  workspace = await mkdtemp("/tmp/hithub-native-rest-merge-");
  await git(["init", "-q", "-b", "main"], workspace);
  await git(["config", "user.name", "Merge Tester"], workspace);
  await git(["config", "user.email", "merge@example.test"], workspace);
  await writeFile(`${workspace}/README.md`, "base\n");
  await git(["add", "README.md"], workspace);
  await git(["commit", "-q", "-m", "base"], workspace);
  await git(["remote", "add", "origin", remote], workspace);
  const base = (await git(["rev-parse", "HEAD"], workspace)).stdout.trim();
  await pushAndVerify("refs/heads/main", base);
  await git(["checkout", "-q", "-b", "feature"], workspace);
  await writeFile(`${workspace}/README.md`, "rest merged feature\n");
  await git(["add", "README.md"], workspace);
  await git(["commit", "-q", "-m", "feature"], workspace);
  const head = (await git(["rev-parse", "HEAD"], workspace)).stdout.trim();
  await pushAndVerify("refs/heads/feature", head);

  const pull = await request(`/api/repos/${repository}/pulls`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      source_ref: "refs/heads/feature",
      target_ref: "refs/heads/main",
      base_oid: base,
      head_oid: head,
    }),
  });
  if (pull.response.status !== 201 || pull.body?.state !== "draft"
      || !/^[0-9]+$/.test(pull.body?.id || "")) {
    throw new Error("REST pull-request creation failed");
  }
  const pullId = pull.body.id;
  const ready = await request(
    `/api/repos/${repository}/pulls/${pullId}`,
    {
      method: "PATCH",
      headers: {"content-type": "application/json", "if-match": '"1"'},
      body: JSON.stringify({state: "open"}),
    },
  );
  if (ready.response.status !== 200 || ready.body?.state !== "open") {
    throw new Error("REST pull-request ready transition failed");
  }
  const merged = await request(
    `/api/repos/${repository}/pulls/${pullId}/merge`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({clean: true, expected_head_oid: head}),
    },
  );
  if (merged.response.status !== 200 || typeof merged.body?.commit_oid !== "string") {
    throw new Error(`REST merge returned ${merged.response.status}`);
  }
  const retried = await request(
    `/api/repos/${repository}/pulls/${pullId}/merge`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({clean: true, expected_head_oid: head}),
    },
  );
  if (retried.response.status !== 200
      || retried.body?.merge_id !== merged.body.merge_id
      || retried.body?.commit_oid !== merged.body.commit_oid) {
    throw new Error(`repeated REST merge did not replay one merge result: first=${JSON.stringify(merged.body)} second=${retried.response.status} ${JSON.stringify(retried.body)}`);
  }

  const clone = `${workspace}/clone`;
  await git(["-c", "protocol.version=0", "clone", "-q", remote, clone], workspace);
  const mergedOid = (await git(["rev-parse", "refs/remotes/origin/main"], clone)).stdout.trim();
  const parents = (await git(["show", "-s", "--format=%P", mergedOid], clone)).stdout.trim().split(/\s+/);
  if (mergedOid !== merged.body.commit_oid || parents.length !== 2
      || !parents.includes(base) || !parents.includes(head)) {
    throw new Error("native clone did not validate the REST-created merge commit");
  }
  console.log("Native Git validated the REST-created merge");
} finally {
  child.kill("SIGTERM");
  if (workspace) await rm(workspace, {recursive: true, force: true});
}
