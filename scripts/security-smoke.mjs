import {spawn} from "node:child_process";

const port = 3300;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port), HITHUB_COOKIE_AUTH: "true"},
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
  if (!ready) throw new Error("CSRF smoke server did not start");

  const shell = await fetch(`http://127.0.0.1:${port}/`);
  const policy = shell.headers.get("content-security-policy") || "";
  if (!shell.ok || !policy.includes("default-src 'self'")
      || !policy.includes("object-src 'none'")
      || !policy.includes("frame-ancestors 'none'")) {
    throw new Error("CSP smoke did not receive a strict content security policy");
  }

  const rejected = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "csrf-rejected"}),
  });
  if (rejected.status !== 403
      || !rejected.headers.get("content-type")?.includes("application/problem+json")) {
    throw new Error("CSRF smoke accepted a mutation without a token");
  }

  const accepted = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      cookie: "hithub_csrf=smoke-token",
      "x-csrf-token": "smoke-token",
    },
    body: JSON.stringify({name: "csrf-accepted"}),
  });
  if (accepted.status !== 201) {
    throw new Error(`CSRF smoke rejected a valid token: ${accepted.status}`);
  }
  console.log("CSRF smoke test passed");
} finally {
  child.kill("SIGTERM");
}
