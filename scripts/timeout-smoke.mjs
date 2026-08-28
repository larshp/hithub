import {spawn} from "node:child_process";

const port = 3603;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port), HITHUB_OPERATION_TIMEOUT_MS: "1000"},
  stdio: "inherit",
});

try {
  let response;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      response = await fetch(`http://127.0.0.1:${port}/health`);
      if (response.ok) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!response?.ok) throw new Error("timeout smoke could not reach health");
  console.log("Operation timeout configuration smoke test passed");
} finally {
  child.kill("SIGTERM");
}
