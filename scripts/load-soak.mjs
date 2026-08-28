import {promisify} from "node:util";
import {execFile, spawn} from "node:child_process";
import {mkdtemp, rm} from "node:fs/promises";

const run = promisify(execFile);
const port = 3705;
const repository = "load-soak-repository";
const remote = `http://127.0.0.1:${port}/${repository}.git`;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {
    ...process.env,
    HITHUB_PORT: String(port),
    HITHUB_FIXTURE_REPOSITORY: repository,
    HITHUB_HTTP_CONCURRENCY: "64",
    HITHUB_GIT_CONCURRENCY: "8",
    HITHUB_RATE_LIMIT: "10000",
  },
  stdio: "inherit",
});
const workspaces = [];

async function waitForHealth() {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/health`);
      if (response.ok) return;
    } catch (_error) {
      // The server may still be transpiling and initializing its database.
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error("load/soak server did not start");
}

async function healthRound() {
  const startedAt = Date.now();
  const responses = await Promise.all(
    Array.from({length: 64}, () => fetch(`http://127.0.0.1:${port}/health`)),
  );
  if (responses.some((response) => !response.ok)) {
    throw new Error("HTTP capacity round returned a non-success response");
  }
  const duration = Date.now() - startedAt;
  if (duration > 30000) {
    throw new Error(`HTTP capacity round exceeded 30 seconds (${duration}ms)`);
  }
}

async function cloneRound(round) {
  const clones = await Promise.all(
    Array.from({length: 8}, async (_value, index) => {
      const workspace = await mkdtemp(`/tmp/hithub-load-soak-${round}-${index}-`);
      workspaces.push(workspace);
      await run("git", ["-c", "protocol.version=0", "clone", "-q", remote, workspace], {
        timeout: 30000,
        maxBuffer: 1024 * 1024 * 8,
      });
      return workspace;
    }),
  );
  await Promise.all(clones.map((workspace) => run("git", ["fsck", "--strict"], {
    cwd: workspace,
    timeout: 30000,
    maxBuffer: 1024 * 1024 * 8,
  })));
}

try {
  await waitForHealth();
  for (let round = 0; round < 10; round += 1) await healthRound();
  for (let round = 0; round < 2; round += 1) await cloneRound(round);
  console.log("Load and soak targets passed: 10x64 HTTP requests and 2x8 Git clones with strict fsck");
} finally {
  child.kill("SIGTERM");
  await Promise.all(workspaces.map((workspace) => rm(workspace, {
    recursive: true,
    force: true,
  })));
}
