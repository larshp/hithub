import {spawn} from "node:child_process";

const port = 3602;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});

try {
  let live;
  let ready;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      [live, ready] = await Promise.all([
        fetch(`http://127.0.0.1:${port}/live`),
        fetch(`http://127.0.0.1:${port}/ready`),
      ]);
      if (live.ok && ready.ok) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  const liveBody = live ? await live.json() : {};
  const readyBody = ready ? await ready.json() : {};
  if (!live?.ok || liveBody.status !== "alive"
      || !ready?.ok || readyBody.status !== "ready") {
    throw new Error("liveness/readiness endpoints were not healthy");
  }
  console.log("Liveness/readiness smoke test passed");
} finally {
  child.kill("SIGTERM");
}
