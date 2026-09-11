// The transpiled ABAP runtime loads each code path the first time it is used,
// so a freshly started server answers /api/repos quickly while the first
// merge, editor, or issue call is still pulling in its module graph. Four
// parallel workers hitting those cold paths at once was enough to blow the
// per-test timeout. Exercise every path the suite depends on once, up front,
// so the tests measure the app rather than its warm-up.
const baseURL = "http://127.0.0.1:3600";
const json = {"content-type": "application/json"};
const repository = `warmup-${Date.now()}`;

async function call(path, options) {
  const response = await fetch(`${baseURL}${path}`, options);
  if (response.status !== 204) await response.text();
  return response;
}

export default async function globalSetup() {
  for (let attempt = 0; attempt < 300; attempt += 1) {
    try {
      if ((await fetch(`${baseURL}/api/repos`)).ok) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  await call("/api/repos", {
    method: "POST", headers: json, body: JSON.stringify({name: repository}),
  });
  const branches = await (await fetch(`${baseURL}/api/repos/${repository}/branches`)).json();
  const head = branches[0]?.oid;
  await call(`/api/repos/${repository}/tags`, {
    method: "POST", headers: json, body: JSON.stringify({name: "warm", oid: head}),
  });
  await call(`/api/repos/${repository}/contents/?ref=main`);
  await call(`/api/repos/${repository}/contents/README.md?ref=main&format=raw`);
  await call(`/api/repos/${repository}/contents/README.md`, {
    method: "PUT",
    headers: json,
    body: JSON.stringify({
      ref: "main", message: "Warm the editor", content: `# ${repository}\n\nwarm\n`,
    }),
  });
  await call(`/api/repos/${repository}/commits?ref=main`);
  await call(`/api/repos/${repository}/compare?base=${head}&head=refs/heads/main`);
  const issue = await (await fetch(`${baseURL}/api/repos/${repository}/issues`, {
    method: "POST", headers: json, body: JSON.stringify({title: "Warm up"}),
  })).json();
  await call(`/api/repos/${repository}/issues/${issue.id}/labels`, {
    method: "POST", headers: json, body: JSON.stringify({label: "warm"}),
  });
  await call(`/api/repos/${repository}/issues/${issue.id}/assignees`);
  const pull = await (await fetch(`${baseURL}/api/repos/${repository}/pulls`, {
    method: "POST",
    headers: json,
    body: JSON.stringify({
      source_ref: "refs/heads/main", target_ref: "refs/heads/main",
      base_oid: head, head_oid: head,
    }),
  })).json();
  await call(`/api/repos/${repository}/pulls/${pull.id}/reviews`, {
    method: "POST", headers: json,
    body: JSON.stringify({id: "warm", state: "commented"}),
  });
  await call(`/api/repos/${repository}/pulls/${pull.id}/comments`);
  await call(`/api/repos/${repository}/audit`);
}
