import {spawn} from "node:child_process";

const port = 3400;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {
    ...process.env,
    HITHUB_PORT: String(port),
    HITHUB_RATE_LIMIT: "2",
    HITHUB_RATE_WINDOW_MS: "60000",
    HITHUB_BODY_LIMIT: "1b",
  },
  stdio: "inherit",
});

try {
  let ready = false;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      ready = (await fetch(`http://127.0.0.1:${port}/health`)).ok;
      if (ready) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!ready) throw new Error("limits smoke server did not start");

  const oversized = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: "{}",
  });
  if (oversized.status !== 413
      || !oversized.headers.get("content-type")?.includes("application/problem+json")) {
    throw new Error(`request-size limit returned ${oversized.status}`);
  }

  const limited = await fetch(`http://127.0.0.1:${port}/health`);
  if (limited.status !== 429
      || !limited.headers.get("retry-after")) {
    throw new Error("rate limit did not return 429 with Retry-After");
  }
  console.log("request and rate limit smoke test passed");
} finally {
  child.kill("SIGTERM");
}
