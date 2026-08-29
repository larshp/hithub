import {promisify} from "node:util";
import {execFile, spawn} from "node:child_process";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {initializeABAP} from "../output/init.mjs";

const run = promisify(execFile);
let workspace;

async function git(args) {
  return run("git", args, {
    cwd: workspace,
    timeout: 30000,
    maxBuffer: 1024 * 1024 * 8,
  });
}

async function writeCommit(payload) {
  return new Promise((resolve, reject) => {
    const child = spawn("git", ["hash-object", "-t", "commit", "-w", "--stdin"], {
      cwd: workspace,
    });
    const output = [];
    const errors = [];
    child.stdout.on("data", (chunk) => output.push(chunk));
    child.stderr.on("data", (chunk) => errors.push(chunk));
    child.on("error", reject);
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(Buffer.concat(errors).toString("utf8")));
      } else {
        resolve(Buffer.concat(output).toString("utf8").trim());
      }
    });
    child.stdin.end(Buffer.from(payload.get(), "hex"));
  });
}

async function fsck(strategy, result) {
  const commit = result.get().commit;
  const {zcl_hithub_commit_codec: CommitCodec} = await import(
    "../output/zcl_hithub_commit_codec.clas.mjs"
  );
  const payload = await CommitCodec.encode({is_commit: commit});
  const oid = await writeCommit(payload);
  if (oid !== result.get().oid.get()) {
    throw new Error(`${strategy} strategy returned a non-canonical commit ID`);
  }
  await git(["fsck", "--strict"]);
}

try {
  workspace = await mkdtemp("/tmp/hithub-native-fsck-");
  await git(["init", "-q", "-b", "main"]);
  await git(["config", "user.name", "Merge Tester"]);
  await git(["config", "user.email", "merge@example.test"]);
  await writeFile(`${workspace}/README.md`, "base\n");
  await git(["add", "README.md"]);
  await git(["commit", "-q", "-m", "base"]);
  const base = (await git(["rev-parse", "HEAD"])).stdout.trim();
  const baseTree = (await git(["rev-parse", "HEAD^{tree}"])).stdout.trim();
  await git(["checkout", "-q", "-b", "feature"]);
  await writeFile(`${workspace}/README.md`, "feature\n");
  await git(["add", "README.md"]);
  await git(["commit", "-q", "-m", "feature"]);
  const head = (await git(["rev-parse", "HEAD"])).stdout.trim();
  const headTree = (await git(["rev-parse", "HEAD^{tree}"])).stdout.trim();

  await initializeABAP();
  const {zcl_hithub_merge_commit: MergeCommit} = await import(
    "../output/zcl_hithub_merge_commit.clas.mjs"
  );
  const {zcl_hithub_squash_merge: SquashMerge} = await import(
    "../output/zcl_hithub_squash_merge.clas.mjs"
  );
  const {zcl_hithub_rebase_merge: RebaseMerge} = await import(
    "../output/zcl_hithub_rebase_merge.clas.mjs"
  );
  const common = {
    iv_expected_head_oid: head,
    iv_current_head_oid: head,
    iv_author: "Merge Tester <merge@example.test> 0 +0000",
    iv_committer: "Merge Tester <merge@example.test> 0 +0000",
    iv_clean: "X",
  };
  const merge = await MergeCommit.create({
    iv_tree_oid: headTree,
    iv_target_oid: base,
    iv_source_oid: head,
    iv_message: "merge strategy",
    ...common,
  });
  await fsck("merge", merge);
  const squash = await SquashMerge.create({
    iv_tree_oid: headTree,
    iv_target_oid: base,
    iv_message: "squash strategy",
    ...common,
  });
  await fsck("squash", squash);
  const rebase = await RebaseMerge.create({
    iv_tree_oid: headTree,
    iv_rebased_parent_oid: base,
    iv_message: "rebase strategy",
    ...common,
  });
  await fsck("rebase", rebase);
  console.log(`git fsck --strict passed after merge, squash, and rebase strategies (base tree ${baseTree})`);
} finally {
  if (workspace) await rm(workspace, {recursive: true, force: true});
}
