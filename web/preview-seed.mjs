// A preview deployment starts from an empty database, and an empty HitHub shows
// nothing but its "no repositories yet" card. Seed the same content on every
// boot so a reviewer lands on populated pages, and so the screenshots compared
// against main always describe the same application state.
//
// Everything below goes through the public REST API rather than through SQL:
// the seed then exercises the same code the preview is there to review, and it
// cannot drift away from the persistence layer the way hand-written INSERTs do.
// That also fixes what the seed can build. Creating a repository writes an
// initial commit holding a README, and the contents API rewrites existing files
// rather than adding new ones, so the history here is a series of edits to that
// README - which is also what the pull request below proposes.

const REPOSITORY = "hithub";
const SECOND_REPOSITORY = "abapgit-mirror";
const BRANCH = "protocol-v2-notes";

const INTRODUCTION = `# HitHub

A git server written in ABAP.

This preview runs the whole thing in your browser: the ABAP sources are
transpiled to JavaScript, a service worker answers every request the page
makes, and the database is compiled in. Nothing you do here leaves your
machine, and a reset puts it back the way you found it.
`;

const WITH_FEATURES = `${INTRODUCTION}
## What it does

- Serves the smart HTTP protocol, so \`git clone\` and \`git push\` work
- Stores repositories, references and objects in the database
- Browses files, commits and references
- Tracks issues with labels, assignees and comments
- Reviews pull requests, and merges them
`;

const WITH_INSTALLATION = `${WITH_FEATURES}
## Installing it

Pull the repository with abapGit and activate it. The SICF node the service
runs under is serialized with the sources, so there is nothing to configure
before the first request.
`;

const WITH_PROTOCOL_NOTES = `${WITH_INSTALLATION}
## Git protocol

Protocol version 2 is negotiated through the \`Git-Protocol\` request header
and falls back to version 1 when the header is absent, so an old client keeps
working against a new server. The v2 \`ls-refs\` command replaces the version 1
reference advertisement: it answers the same references, but the client asks
for the prefixes it cares about instead of receiving every reference in the
repository.
`;

function shortName(reference) {
  return String(reference).replace(/^refs\/heads\//, "");
}

export async function seedPreviewContent(request) {
  async function call(method, path, body, headers = {}) {
    const response = await request({
      method,
      path,
      body: body === undefined ? undefined : JSON.stringify(body),
      headers: body === undefined
        ? headers
        : {"content-type": "application/json", ...headers},
    });
    if (response.status >= 400) {
      throw new Error(`${method} ${path} answered ${response.status}`);
    }
    const text = new TextDecoder().decode(response.body);
    return text === "" ? undefined : JSON.parse(text);
  }

  function commit(reference, message, content) {
    return call("PUT", `/api/repos/${REPOSITORY}/contents/README.md`, {
      ref: shortName(reference),
      message,
      content,
    });
  }

  await call("POST", "/api/repos", {
    name: REPOSITORY,
    description: "A git server written in ABAP",
  });

  const branches = await call("GET", `/api/repos/${REPOSITORY}/branches`);
  const main = branches.find((branch) => shortName(branch.name) === "main")
    || branches[0];

  await commit(main.name, "Say what HitHub is", INTRODUCTION);
  await commit(main.name, "List what the server can do", WITH_FEATURES);
  const base = await commit(main.name, "Describe how to install it",
    WITH_INSTALLATION);

  await call("POST", `/api/repos/${REPOSITORY}/branches`, {
    name: `refs/heads/${BRANCH}`,
    oid: base.commit_oid,
  });
  const head = await commit(`refs/heads/${BRANCH}`,
    "Write down how protocol v2 is negotiated", WITH_PROTOCOL_NOTES);

  const pull = await call("POST", `/api/repos/${REPOSITORY}/pulls`, {
    title: "Write down how protocol v2 is negotiated",
    body: "The README stops at installation. Describe the version handshake "
      + "and what replaces the v1 reference advertisement, so the next reader "
      + "does not have to work it out from the packet parser.",
    state: "open",
    source_ref: `refs/heads/${BRANCH}`,
    target_ref: main.name,
    base_oid: base.commit_oid,
    head_oid: head.commit_oid,
  });
  await call("POST", `/api/repos/${REPOSITORY}/pulls/${pull.id}/comments`, {
    id: "comment-1",
    body: "Reads well. Worth saying that the prefixes are optional, since a "
      + "client that sends none still gets every reference.",
  });
  await call("POST", `/api/repos/${REPOSITORY}/pulls/${pull.id}/reviews`, {
    id: "review-1",
    state: "approved",
    body: "Accurate against the packet parser.",
  });

  const shallow = await call("POST", `/api/repos/${REPOSITORY}/issues`, {
    title: "Shallow clones are rejected with a protocol error",
    body: "`git clone --depth 1` fails during negotiation: the server answers "
      + "a flush packet where the client expects a shallow line.",
  });
  await call("POST", `/api/repos/${REPOSITORY}/issues/${shallow.id}/labels`,
    {label: "git-protocol"});
  await call("POST", `/api/repos/${REPOSITORY}/issues/${shallow.id}/labels`,
    {label: "bug"});
  await call("POST", `/api/repos/${REPOSITORY}/issues/${shallow.id}/comments`, {
    id: "comment-1",
    body: "Reproduced against a fresh repository. The capability advertisement "
      + "does not announce `shallow`, so the client should not be sending it "
      + "either - that is the actual defect.",
  });

  const deltas = await call("POST", `/api/repos/${REPOSITORY}/issues`, {
    title: "Packfile delta resolution is quadratic in the chain length",
    body: "Receiving a pack with long delta chains spends most of its time "
      + "reconstructing bases that were already reconstructed once.",
  });
  await call("POST", `/api/repos/${REPOSITORY}/issues/${deltas.id}/labels`,
    {label: "performance"});

  const names = await call("POST", `/api/repos/${REPOSITORY}/issues`, {
    title: "Repository names are not validated on create",
    body: "A name containing a slash created a repository that could not be "
      + "addressed afterwards.",
  });
  // Every issue update is guarded by an entity tag, so a state change has to
  // name the version it was made against, exactly as the browser does.
  await call("PATCH", `/api/repos/${REPOSITORY}/issues/${names.id}`,
    {state: "closed"}, {"if-match": `"${names.version}"`});

  await call("POST", "/api/repos", {
    name: SECOND_REPOSITORY,
    description: "Fixtures used to exercise the smart HTTP protocol",
  });
}
