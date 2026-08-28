import {spawn} from "node:child_process";

const port = 3600;
const lines = [];
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: ["ignore", "pipe", "inherit"],
});
child.stdout.on("data", (chunk) => {
  lines.push(...chunk.toString("utf8").split("\n").filter(Boolean));
});

try {
  let response;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      response = await fetch(`http://127.0.0.1:${port}/health`, {
        headers: {"x-request-id": "logging-correlation"},
      });
      if (response.ok) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!response?.ok) throw new Error("logging smoke could not reach health");
  if (response.headers.get("x-request-id") !== "logging-correlation") {
    throw new Error("request correlation ID was not returned");
  }
  await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "authorization": "Bearer telemetry-secret",
    },
    body: JSON.stringify({name: "telemetry-repository", secret: "body-secret"}),
  });
  await new Promise((resolve) => setTimeout(resolve, 50));
  const output = lines.join("\n");
  if (output.includes("telemetry-secret") || output.includes("body-secret")) {
    throw new Error("structured logs exposed request secrets");
  }
  const records = lines.map((line) => {
    try {
      return JSON.parse(line);
    } catch (_error) {
      return null;
    }
  }).filter(Boolean);
  if (!records.some((record) => record.event === "server.started")
      || !records.some((record) => record.event === "http.request"
        && record.method === "GET" && record.path === "/health"
        && record.request_id === "logging-correlation"
        && record.status === 200
        && Number.isInteger(record.duration_ms))) {
    throw new Error("structured request logs were not emitted");
  }
  console.log("Structured logging smoke test passed");
} finally {
  child.kill("SIGTERM");
}
