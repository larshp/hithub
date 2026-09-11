import {promisify} from "node:util";
import {execFile} from "node:child_process";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {spawn} from "node:child_process";
import {chromium} from "playwright";

const run = promisify(execFile);
const port = 3700;
const repository = "native-ui-merge-repository";
const remote = `http://127.0.0.1:${port}/${repository}.git`;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});
let workspace;
let browser;

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

  workspace = await mkdtemp("/tmp/hithub-native-ui-merge-");
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
  await writeFile(`${workspace}/README.md`, "merged feature\n");
  await git(["add", "README.md"], workspace);
  await git(["commit", "-q", "-m", "feature"], workspace);
  const head = (await git(["rev-parse", "HEAD"], workspace)).stdout.trim();
  await pushAndVerify("refs/heads/feature", head);

  browser = await chromium.launch({headless: true});
  const page = await browser.newPage();
  await page.goto(
    `http://127.0.0.1:${port}/ui/repos/${repository}/pulls/new`,
    {waitUntil: "networkidle"},
  );
  await page.locator("#pull-id").fill("ui-merge-request");
  await page.locator("#pull-source_ref").fill("refs/heads/feature");
  await page.locator("#pull-target_ref").fill("refs/heads/main");
  await page.locator("#pull-base_oid").fill(base);
  await page.locator("#pull-head_oid").fill(head);
  await page.getByRole("button", {name: "Create pull request"}).click();
  await page.waitForURL(/\/pulls\/ui-merge-request$/);
  await page.getByRole("button", {name: "Ready for review"}).click();
  await page.getByRole("button", {name: "Merge pull request"}).click();
  await page.getByLabel("State: merged").waitFor();

  const clone = `${workspace}/clone`;
  await git(["-c", "protocol.version=0", "clone", "-q", remote, clone], workspace);
  const merged = (await git(["rev-parse", "refs/remotes/origin/main"], clone)).stdout.trim();
  const parents = (await git(["show", "-s", "--format=%P", merged], clone)).stdout.trim().split(/\s+/);
  if (merged === head || parents.length !== 2 || !parents.includes(base)
      || !parents.includes(head)) {
    throw new Error("native clone did not validate the UI-created merge commit");
  }
  console.log("Native Git validated the UI-created merge");
} finally {
  await browser?.close();
  child.kill("SIGTERM");
  if (workspace) await rm(workspace, {recursive: true, force: true});
}
