import {spawn} from "node:child_process";

const port = 3601;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});

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
  if (!healthy) throw new Error("metrics smoke could not reach health");
  const response = await fetch(`http://127.0.0.1:${port}/metrics`);
  const body = await response.json();
  if (!response.ok || !Number.isInteger(body.requests) || body.requests < 1
      || !Number.isInteger(body.statuses["200"])
      || body.statuses["200"] < 1
      || !Number.isInteger(body.duration_ms_max)) {
    throw new Error("service metrics did not report health traffic");
  }
  console.log("Service metrics smoke test passed");
} finally {
  child.kill("SIGTERM");
}
