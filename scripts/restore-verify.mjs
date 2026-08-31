import {promisify} from "node:util";
import {execFile} from "node:child_process";
import {cp, mkdtemp, rm, writeFile} from "node:fs/promises";

const run = promisify(execFile);
let root;

async function git(args, cwd) {
  return run("git", args, {cwd, timeout: 30000, maxBuffer: 1024 * 1024 * 4});
}

try {
  root = await mkdtemp("/tmp/hithub-restore-verify-");
  const source = `${root}/source`;
  const restored = `${root}/restored`;
  const clone = `${root}/clone`;
  await mkdtemp(`${root}/work-`);
  await run("git", ["init", "-q", source]);
  await git(["config", "user.name", "Restore Tester"], source);
  await git(["config", "user.email", "restore@example.test"], source);
  await writeFile(`${source}/README.md`, "restored\n");
  await git(["add", "README.md"], source);
  await git(["commit", "-q", "-m", "restore"], source);
  const expected = (await git(["rev-parse", "HEAD"], source)).stdout.trim();
  await cp(`${source}/.git`, `${restored}/.git`, {recursive: true});
  await writeFile(`${restored}/README.md`, "restored\n");
  await git(["fsck", "--strict"], restored);
  await git(["clone", "-q", restored, clone], root);
  const actual = (await git(["rev-parse", "HEAD"], clone)).stdout.trim();
  if (actual !== expected) throw new Error("restored clone changed the commit ID");
  console.log("Restore verification passed: fsck and clone preserved the commit");
} finally {
  if (root) await rm(root, {recursive: true, force: true});
}
