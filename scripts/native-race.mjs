import {promisify} from "node:util";
import {execFile} from "node:child_process";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {spawn} from "node:child_process";

const run = promisify(execFile);
const port = 3702;
const repository = "native-race-repository";
const remote = `http://127.0.0.1:${port}/${repository}.git`;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});
let workspace;

async function git(args) {
  try {
    return await run("git", args, {
      cwd: workspace,
      timeout: 30000,
      maxBuffer: 1024 * 1024 * 8,
    });
  } catch (error) {
    throw new Error(`${error.message}\nstdout: ${error.stdout}\nstderr: ${error.stderr}`);
  }
}

async function request(path, options) {
  const response = await fetch(`http://127.0.0.1:${port}${path}`, options);
  return {response, body: await response.json()};
}

async function pushRef(source, target, oid) {
  try {
    await git(["push", "-q", "origin", `${source}:${target}`]);
  } catch (_error) {
    // Verify the durable ref below because the local receive-pack client can
    // report a status framing error after the server has committed it.
  }
  const listed = await request(`/api/repos/${repository}/branches`);
  return listed.response.status === 200
    && listed.body.some((item) => item.name === target && item.oid === oid);
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
  if (!healthy) throw new Error("race server did not start");
  const created = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: repository, default_branch: "main"}),
  });
  if (created.response.status !== 201) {
    throw new Error(`repository create returned ${created.response.status}`);
  }

  workspace = await mkdtemp("/tmp/hithub-native-race-");
  await git(["init", "-q", "-b", "main"]);
  await git(["config", "user.name", "Merge Tester"]);
  await git(["config", "user.email", "merge@example.test"]);
  await writeFile(`${workspace}/README.md`, "base\n");
  await git(["add", "README.md"]);
  await git(["commit", "-q", "-m", "base"]);
  await git(["remote", "add", "origin", remote]);
  const base = (await git(["rev-parse", "HEAD"])).stdout.trim();
  await pushRef("HEAD", "refs/heads/main", base);

  await git(["checkout", "-q", "-b", "feature"]);
  await writeFile(`${workspace}/README.md`, "feature\n");
  await git(["add", "README.md"]);
  await git(["commit", "-q", "-m", "feature"]);
  const head = (await git(["rev-parse", "HEAD"])).stdout.trim();
  await git(["checkout", "-q", "-b", "racer", base]);
  await writeFile(`${workspace}/racer.txt`, "racing push\n");
  await git(["add", "racer.txt"]);
  await git(["commit", "-q", "-m", "racing push"]);
  const racer = (await git(["rev-parse", "HEAD"])).stdout.trim();
  await git(["checkout", "-q", "feature"]);
  await pushRef("HEAD", "refs/heads/feature", head);

  const pull = await request(`/api/repos/${repository}/pulls`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      id: "race-merge-request",
      source_ref: "refs/heads/feature",
      target_ref: "refs/heads/main",
      base_oid: base,
      head_oid: head,
    }),
  });
  if (pull.response.status !== 201) throw new Error("race pull-request creation failed");
  const ready = await request(`/api/repos/${repository}/pulls/race-merge-request`, {
    method: "PATCH",
    headers: {"content-type": "application/json", "if-match": '"1"'},
    body: JSON.stringify({state: "open"}),
  });
  if (ready.response.status !== 200) throw new Error("race pull-request ready transition failed");

  const mergePromise = request(
    `/api/repos/${repository}/pulls/race-merge-request/merge`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({clean: true, expected_head_oid: head}),
    },
  );
  const pushPromise = pushRef("refs/heads/racer", "refs/heads/main", racer);
  const [merged, pushWon] = await Promise.all([mergePromise, pushPromise]);
  const branches = await request(`/api/repos/${repository}/branches`);
  const target = branches.body.find((item) => item.name === "refs/heads/main");
  if (!target) throw new Error("race target branch disappeared");

  if (target.oid === racer) {
    if (merged.response.status === 200 || !pushWon) {
      throw new Error("race push won without rejecting the merge");
    }
  } else {
    if (merged.response.status !== 200 || target.oid !== merged.body.commit_oid) {
      throw new Error(`race produced an unexpected target: ${merged.response.status} ${target.oid}`);
    }
    const clone = `${workspace}/clone`;
    await run("git", ["-c", "protocol.version=0", "clone", "-q", remote, clone], {
      cwd: workspace,
      timeout: 30000,
    });
    const parents = (await run(
      "git", ["show", "-s", "--format=%P", target.oid], {cwd: clone},
    )).stdout.trim().split(/\s+/);
    if (parents.length !== 2 || !parents.includes(base) || !parents.includes(head)
        || parents.includes(racer)) {
      throw new Error("race merge contains the wrong parents");
    }
  }
  console.log("Concurrent native push and REST merge produced a safe result");
} finally {
  child.kill("SIGTERM");
  if (workspace) await rm(workspace, {recursive: true, force: true});
}
