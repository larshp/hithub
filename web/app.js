const headerStatus = document.querySelector("#header-status");
const serviceStatus = document.querySelector("#service-status");
const dashboard = document.querySelector("#repository-dashboard");
const pageTitle = document.querySelector("#page-title");
const pageLede = document.querySelector(".lede");

async function checkService() {
  try {
    const response = await fetch("/health", {headers: {accept: "application/json"}});
    if (!response.ok) throw new Error(`health returned ${response.status}`);
    const body = await response.json();
    if (body.status !== "ok") throw new Error("health response was not ok");
    headerStatus.textContent = "Service online";
    serviceStatus.textContent = "Online";
    serviceStatus.classList.add("is-positive");
  } catch (error) {
    headerStatus.textContent = "Service unavailable";
    serviceStatus.textContent = "Unavailable";
    serviceStatus.classList.add("is-negative");
    console.warn("HitHub health check failed", error);
  }
}

checkService();

function repositoryCard(repository) {
  const card = document.createElement("article");
  card.className = "repository-card";
  const title = document.createElement("h3");
  const link = document.createElement("a");
  link.href = `/ui/repos/${encodeURIComponent(repository.name)}`;
  link.textContent = repository.name;
  title.append(link);
  const description = document.createElement("p");
  description.textContent = repository.description || "No description yet.";
  const metadata = document.createElement("dl");
  metadata.className = "repository-meta";
  for (const [label, value] of [
    ["Default branch", repository.default_branch],
    ["Version", String(repository.version)],
  ]) {
    const term = document.createElement("dt");
    term.textContent = label;
    const detail = document.createElement("dd");
    detail.textContent = value;
    metadata.append(term, detail);
  }
  card.append(title, description, metadata);
  return card;
}

function renderMarkdownSafe(markdown) {
  const fragment = document.createDocumentFragment();
  let codeBlock = null;
  for (const line of String(markdown || "").split("\n")) {
    if (line.startsWith("```")) {
      if (codeBlock) {
        fragment.append(codeBlock);
        codeBlock = null;
      } else {
        codeBlock = document.createElement("pre");
        codeBlock.className = "readme-code";
        codeBlock.append(document.createElement("code"));
      }
      continue;
    }
    if (codeBlock) {
      codeBlock.querySelector("code").textContent += `${line}\n`;
      continue;
    }
    const heading = line.match(/^(#{1,3})\s+(.+)$/);
    if (heading) {
      const element = document.createElement(`h${heading[1].length + 1}`);
      element.textContent = heading[2];
      fragment.append(element);
    } else if (line.trim()) {
      const paragraph = document.createElement("p");
      paragraph.textContent = line;
      fragment.append(paragraph);
    }
  }
  if (codeBlock) fragment.append(codeBlock);
  return fragment;
}

async function loadRepositories() {
  try {
    const response = await fetch("/api/repos", {headers: {accept: "application/json"}});
    if (!response.ok) throw new Error(`repository list returned ${response.status}`);
    const repositories = await response.json();
    dashboard.replaceChildren();
    if (!repositories.length) {
      const empty = document.createElement("p");
      empty.className = "muted-message";
      empty.textContent = "No repositories yet. Create one to begin browsing.";
      dashboard.append(empty);
      return;
    }
    repositories.forEach((repository) => dashboard.append(repositoryCard(repository)));
  } catch (error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "Repositories could not be loaded. Try again shortly.";
    dashboard.append(failure);
    console.warn("HitHub repository list failed", error);
  }
}

const repositoryRoute = window.location.pathname.match(/^\/ui\/repos\/([^/]+)$/);
const treeRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/files\/([^/]+)(?:\/(.*))?$/,
);
const blobRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/blob\/([^/]+)\/(.+)$/,
);
const historyRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/commits\/([^/]+)$/,
);
const commitRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/commit\/([^/]+)$/,
);
const compareRoute = window.location.pathname.match(/^\/ui\/repos\/([^/]+)\/compare$/);
if (window.location.pathname === "/ui/create") showCreateForm();
else if (commitRoute) showCommitDetail(
  decodeURIComponent(commitRoute[1]), decodeURIComponent(commitRoute[2]),
);
else if (compareRoute) showCompareView(decodeURIComponent(compareRoute[1]));
else if (historyRoute) showCommitHistory(
  decodeURIComponent(historyRoute[1]), decodeURIComponent(historyRoute[2]),
);
else if (blobRoute) showBlobViewer(
  decodeURIComponent(blobRoute[1]), decodeURIComponent(blobRoute[2]),
  decodeURIComponent(blobRoute[3]),
);
else if (treeRoute) showTreeBrowser(
  decodeURIComponent(treeRoute[1]), decodeURIComponent(treeRoute[2]),
  treeRoute[3] ? decodeURIComponent(treeRoute[3]) : "",
);
else if (repositoryRoute) showRepositoryOverview(decodeURIComponent(repositoryRoute[1]));
else loadRepositories();

function showCreateForm() {
  pageTitle.textContent = "Create a repository";
  pageLede.textContent = "Set up a repository with a stable name and default branch.";
  dashboard.replaceChildren();
  const form = document.createElement("form");
  form.className = "repository-form";
  const nameLabel = document.createElement("label");
  nameLabel.htmlFor = "repository-name";
  nameLabel.textContent = "Name";
  const name = document.createElement("input");
  name.id = "repository-name";
  name.name = "name";
  name.required = true;
  name.pattern = "[A-Za-z0-9][A-Za-z0-9._-]*";
  name.maxLength = 100;
  name.autocomplete = "off";
  const descriptionLabel = document.createElement("label");
  descriptionLabel.htmlFor = "repository-description";
  descriptionLabel.textContent = "Description ";
  const descriptionOptional = document.createElement("span");
  descriptionOptional.className = "optional";
  descriptionOptional.textContent = "(optional)";
  descriptionLabel.append(descriptionOptional);
  const description = document.createElement("textarea");
  description.id = "repository-description";
  description.name = "description";
  description.maxLength = 255;
  description.rows = 3;
  const branchLabel = document.createElement("label");
  branchLabel.htmlFor = "repository-branch";
  branchLabel.textContent = "Default branch ";
  const branchOptional = document.createElement("span");
  branchOptional.className = "optional";
  branchOptional.textContent = "(optional)";
  branchLabel.append(branchOptional);
  const branch = document.createElement("input");
  branch.id = "repository-branch";
  branch.name = "default_branch";
  branch.value = "main";
  branch.maxLength = 160;
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Create repository";
  const status = document.createElement("p");
  status.className = "form-status";
  status.id = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  form.append(nameLabel, name, descriptionLabel, description,
    branchLabel, branch, submit, status);
  dashboard.append(form);
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const status = form.querySelector("#form-status");
    const data = Object.fromEntries(new FormData(form));
    status.textContent = "Creating repository…";
    try {
      const response = await fetch("/api/repos", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": globalThis.crypto?.randomUUID?.() || String(Date.now()),
        },
        body: JSON.stringify(data),
      });
      const body = await response.json();
      if (!response.ok) {
        status.className = "form-status is-error";
        status.textContent = body.detail || "Repository could not be created.";
        return;
      }
      status.className = "form-status is-success";
      status.textContent = "Repository created.";
      const link = document.createElement("a");
      link.href = `/ui/repos/${encodeURIComponent(body.name)}`;
      link.textContent = "Open repository";
      status.append(" ", link);
    } catch (_error) {
      status.className = "form-status is-error";
      status.textContent = "Repository could not be created. Try again shortly.";
    }
  });
}

async function showRepositoryOverview(name) {
  pageTitle.textContent = name;
  pageLede.textContent = "Repository overview, references, and clone information.";
  dashboard.replaceChildren();
  const loading = document.createElement("p");
  loading.className = "muted-message";
  loading.textContent = "Loading repository…";
  dashboard.append(loading);
  try {
    const encoded = encodeURIComponent(name);
    const [repositoryResponse, branchesResponse, tagsResponse] = await Promise.all([
      fetch(`/api/repos/${encoded}`),
      fetch(`/api/repos/${encoded}/branches`),
      fetch(`/api/repos/${encoded}/tags`),
    ]);
    if (!repositoryResponse.ok) throw new Error("repository not found");
    const repository = await repositoryResponse.json();
    const branches = branchesResponse.ok ? await branchesResponse.json() : [];
    const tags = tagsResponse.ok ? await tagsResponse.json() : [];
    dashboard.replaceChildren();
    const header = document.createElement("div");
    header.className = "overview-header";
    const clone = document.createElement("code");
    clone.textContent = `${window.location.origin}/git/${repository.name}.git`;
    header.append(clone);
    const details = document.createElement("dl");
    details.className = "repository-meta overview-meta";
    for (const [label, value] of [
      ["Default branch", repository.default_branch],
      ["Version", String(repository.version)],
      ["Branches", String(branches.length)],
      ["Tags", String(tags.length)],
    ]) {
      const term = document.createElement("dt");
      term.textContent = label;
      const detail = document.createElement("dd");
      detail.textContent = value;
      details.append(term, detail);
    }
    const referenceColumns = document.createElement("div");
    referenceColumns.className = "reference-columns";
    const selector = document.createElement("div");
    selector.className = "reference-selector";
    const selectorLabel = document.createElement("label");
    selectorLabel.htmlFor = "reference-choice";
    selectorLabel.textContent = "Open reference";
    const referenceChoice = document.createElement("select");
    referenceChoice.id = "reference-choice";
    referenceChoice.setAttribute("aria-label", "Open branch or tag");
    for (const reference of [...branches, ...tags]) {
      const option = document.createElement("option");
      option.value = reference.name;
      option.textContent = reference.name;
      referenceChoice.append(option);
    }
    referenceChoice.addEventListener("change", () => {
      const selected = referenceChoice.value.replace(/^refs\/(heads|tags)\//, "");
      const kind = referenceChoice.value.startsWith("refs/tags/") ? "tags" : "files";
      window.location.href = `/ui/repos/${encoded}/${kind}/${encodeURIComponent(selected)}`;
    });
    selector.append(selectorLabel, referenceChoice);
    for (const [heading, references, prefix] of [
      ["Branches", branches, "refs/heads/"],
      ["Tags", tags, "refs/tags/"],
    ]) {
      const section = document.createElement("section");
      section.className = "reference-section";
      const title = document.createElement("h3");
      title.textContent = heading;
      const list = document.createElement("ul");
      if (!references.length) {
        const empty = document.createElement("li");
        empty.className = "muted-message";
        empty.textContent = `No ${heading.toLowerCase()} yet.`;
        list.append(empty);
      }
      references.forEach((reference) => {
        const item = document.createElement("li");
        const link = document.createElement("a");
        const shortName = reference.name.startsWith(prefix)
          ? reference.name.slice(prefix.length) : reference.name;
        link.href = `/ui/repos/${encoded}/files/${encodeURIComponent(shortName)}`;
        link.textContent = shortName;
        item.append(link);
        list.append(item);
      });
      section.append(title, list);
      referenceColumns.append(section);
    }
    const readme = document.createElement("section");
    readme.className = "readme-panel";
    const readmeTitle = document.createElement("h3");
    readmeTitle.textContent = "README";
    const readmeContent = document.createElement("div");
    readmeContent.className = "readme-content";
    readmeContent.append(...renderMarkdownSafe(repository.readme).childNodes);
    if (!readmeContent.childNodes.length) {
      readmeContent.className = "readme-content muted-message";
      readmeContent.textContent = "No README is available for this repository.";
    }
    readme.append(readmeTitle, readmeContent);
    dashboard.append(header, details, selector, referenceColumns, readme);
  } catch (_error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "This repository could not be loaded.";
    dashboard.append(failure);
  }
}

async function showCompareView(repository) {
  pageTitle.textContent = "Compare references";
  pageLede.textContent = `${repository} · review changes between two branches or tags`;
  dashboard.replaceChildren();
  const form = document.createElement("form");
  form.className = "compare-form";
  const heading = document.createElement("h2");
  heading.textContent = "Choose references";
  const baseLabel = document.createElement("label");
  baseLabel.htmlFor = "compare-base";
  baseLabel.textContent = "Base reference";
  const base = document.createElement("select");
  base.id = "compare-base";
  base.required = true;
  const headLabel = document.createElement("label");
  headLabel.htmlFor = "compare-head";
  headLabel.textContent = "Compare with";
  const head = document.createElement("select");
  head.id = "compare-head";
  head.required = true;
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Compare";
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  form.append(heading, baseLabel, base, headLabel, head, submit, status);
  dashboard.append(form);
  try {
    const encoded = encodeURIComponent(repository);
    const [branchesResponse, tagsResponse] = await Promise.all([
      fetch(`/api/repos/${encoded}/branches`),
      fetch(`/api/repos/${encoded}/tags`),
    ]);
    if (!branchesResponse.ok || !tagsResponse.ok) throw new Error("references unavailable");
    const references = [
      ...(await branchesResponse.json()),
      ...(await tagsResponse.json()),
    ];
    references.forEach((reference) => {
      const option = document.createElement("option");
      option.value = reference.name;
      option.textContent = reference.name.replace(/^refs\/(heads|tags)\//, "");
      base.append(option.cloneNode(true));
      head.append(option);
    });
    const query = new URLSearchParams(window.location.search);
    if (query.has("base")) base.value = query.get("base");
    if (query.has("head")) head.value = query.get("head");
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      const params = new URLSearchParams({base: base.value, head: head.value});
      status.textContent = "Loading comparison…";
      try {
        const response = await fetch(`/api/repos/${encoded}/compare?${params}`);
        if (!response.ok) throw new Error(`compare returned ${response.status}`);
        const payload = await response.json();
        dashboard.append(renderUnifiedDiffSafe(payload));
        status.textContent = `${base.value} compared with ${head.value}.`;
      } catch (_error) {
        status.className = "form-status is-error";
        status.textContent = "This comparison could not be loaded.";
      }
    });
  } catch (_error) {
    status.className = "form-status is-error";
    status.textContent = "References could not be loaded.";
  }
}

function renderTreeEntry(entry, repository, branch, path) {
  const item = document.createElement("li");
  const link = document.createElement("a");
  const entryPath = path ? `${path}/${entry.name}` : entry.name;
  link.href = entry.type === "tree"
    ? `/ui/repos/${encodeURIComponent(repository)}/files/${encodeURIComponent(branch)}/${encodeURIComponent(entryPath)}`
    : `/ui/repos/${encodeURIComponent(repository)}/blob/${encodeURIComponent(branch)}/${encodeURIComponent(entryPath)}`;
  link.textContent = entry.name;
  item.append(link);
  if (entry.last_commit) {
    const summary = document.createElement("span");
    summary.className = "entry-summary";
    summary.textContent = ` — ${entry.last_commit}`;
    item.append(summary);
  }
  return item;
}

function sourceLanguage(path) {
  const extension = path.split(".").pop()?.toLowerCase();
  const languages = {
    abap: "abap",
    js: "javascript",
    mjs: "javascript",
    cjs: "javascript",
    ts: "typescript",
    css: "css",
    html: "markup",
    htm: "markup",
    json: "json",
    md: "markdown",
    yaml: "yaml",
    yml: "yaml",
    xml: "markup",
  };
  return languages[extension] || "plain";
}

function appendHighlightedLine(line, code) {
  const tokenPattern = /(\/\/.*$|#.*$|\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|\b(?:class|const|else|export|for|from|function|if|import|let|new|return|SELECT|FROM|WHERE|DATA|TYPE|METHOD|ENDMETHOD|DEFINE|END-OF-DEFINITION)\b)/gi;
  let offset = 0;
  for (const match of line.matchAll(tokenPattern)) {
    const start = match.index ?? 0;
    if (start > offset) code.append(document.createTextNode(line.slice(offset, start)));
    const token = document.createElement("span");
    token.className = /^(\/\/|#)/.test(match[0])
      ? "token-comment"
      : /^[\"']/.test(match[0])
        ? "token-string"
        : "token-keyword";
    token.textContent = match[0];
    code.append(token);
    offset = start + match[0].length;
  }
  if (offset < line.length) code.append(document.createTextNode(line.slice(offset)));
  if (!line) code.append(document.createTextNode(" "));
}

function renderSourceSafe(viewer, source, path) {
  viewer.replaceChildren();
  viewer.className = `blob-viewer source-code language-${sourceLanguage(path)}`;
  viewer.setAttribute("aria-label", `Source for ${path}`);
  source.split("\n").forEach((line, index, lines) => {
    const row = document.createElement("span");
    row.className = "source-line";
    row.setAttribute("data-line", String(index + 1));
    const code = document.createElement("span");
    appendHighlightedLine(line, code);
    row.append(code);
    viewer.append(row);
    if (index < lines.length - 1) viewer.append(document.createTextNode("\n"));
  });
}

function renderUnifiedDiffSafe(payload) {
  const panel = document.createElement("section");
  panel.className = "diff-panel unified-diff";
  const title = document.createElement("h2");
  title.textContent = "Unified diff";
  const pre = document.createElement("pre");
  pre.className = "diff-viewer";
  const patches = Array.isArray(payload?.files)
    ? payload.files.map((file) => file.patch || file.diff || "").filter(Boolean)
    : [payload?.diff || payload?.patch || payload?.unified_diff || ""];
  const source = patches.join("\n");
  const split = renderSplitDiffSafe(source);
  split.hidden = true;
  const toggle = document.createElement("button");
  toggle.className = "button diff-toggle";
  toggle.type = "button";
  toggle.textContent = "Show split view";
  toggle.addEventListener("click", () => {
    const showingSplit = !split.hidden;
    split.hidden = showingSplit;
    pre.hidden = !showingSplit;
    toggle.textContent = showingSplit ? "Show split view" : "Show unified view";
  });
  if (!source) {
    pre.className = "diff-viewer muted-message";
    pre.textContent = "No textual changes are available.";
    toggle.hidden = true;
  } else {
    source.split("\n").forEach((line, index, lines) => {
      const row = document.createElement("span");
      row.className = line.startsWith("+++") || line.startsWith("---")
        ? "diff-file"
        : line.startsWith("@@")
          ? "diff-hunk"
          : line.startsWith("+")
            ? "diff-added"
            : line.startsWith("-")
              ? "diff-removed"
              : "diff-context";
      row.textContent = line;
      pre.append(row);
      if (index < lines.length - 1) pre.append(document.createTextNode("\n"));
    });
  }
  panel.append(title, toggle, pre, split);
  return panel;
}

function renderSplitDiffSafe(source) {
  const table = document.createElement("table");
  table.className = "split-diff";
  const caption = document.createElement("caption");
  caption.textContent = "Split diff";
  const header = document.createElement("tr");
  for (const label of ["Base", "Compare with"]) {
    const cell = document.createElement("th");
    cell.scope = "col";
    cell.textContent = label;
    header.append(cell);
  }
  const head = document.createElement("thead");
  head.append(header);
  const body = document.createElement("tbody");
  const lines = source ? source.split("\n") : ["No textual changes are available."];
  lines.forEach((line) => {
    const row = document.createElement("tr");
    const left = document.createElement("td");
    const right = document.createElement("td");
    if (line.startsWith("+") && !line.startsWith("+++")) {
      right.className = "diff-added";
      right.textContent = line.slice(1);
    } else if (line.startsWith("-") && !line.startsWith("---")) {
      left.className = "diff-removed";
      left.textContent = line.slice(1);
    } else {
      left.className = "diff-context";
      right.className = "diff-context";
      left.textContent = line.replace(/^ /, "");
      right.textContent = line.replace(/^ /, "");
    }
    row.append(left, right);
    body.append(row);
  });
  table.append(caption, head, body);
  return table;
}

async function showTreeBrowser(repository, branch, path) {
  pageTitle.textContent = repository;
  pageLede.textContent = `Files on ${branch}${path ? ` · ${path}` : ""}`;
  dashboard.replaceChildren();
  const breadcrumb = document.createElement("p");
  breadcrumb.className = "breadcrumb";
  breadcrumb.textContent = `Repository / ${branch}${path ? ` / ${path}` : ""}`;
  const list = document.createElement("ul");
  list.className = "tree-list";
  const loading = document.createElement("li");
  loading.className = "muted-message";
  loading.textContent = "Loading files…";
  list.append(loading);
  dashboard.append(breadcrumb, list);
  try {
    const encodedPath = path.split("/").filter(Boolean).map(encodeURIComponent).join("/");
    const response = await fetch(
      `/api/repos/${encodeURIComponent(repository)}/contents/${encodedPath}?ref=${encodeURIComponent(branch)}`,
    );
    if (!response.ok) throw new Error(`contents returned ${response.status}`);
    const body = await response.json();
    list.replaceChildren();
    if (!Array.isArray(body.entries) || !body.entries.length) {
      const empty = document.createElement("li");
      empty.className = "muted-message";
      empty.textContent = "This directory is empty.";
      list.append(empty);
      return;
    }
    body.entries.forEach((entry) => list.append(
      renderTreeEntry(entry, repository, branch, path),
    ));
  } catch (_error) {
    list.replaceChildren();
    const failure = document.createElement("li");
    failure.className = "muted-message";
    failure.textContent = "This directory could not be loaded.";
    list.append(failure);
  }
}

async function showBlobViewer(repository, branch, path) {
  pageTitle.textContent = path.split("/").pop() || "Blob";
  pageLede.textContent = `${repository} · ${branch} · ${path}`;
  dashboard.replaceChildren();
  const encodedPath = path.split("/").map(encodeURIComponent).join("/");
  const rawUrl = `/api/repos/${encodeURIComponent(repository)}/contents/${encodedPath}?ref=${encodeURIComponent(branch)}&format=raw`;
  const actions = document.createElement("p");
  actions.className = "blob-actions";
  const download = document.createElement("a");
  download.className = "button raw-download";
  download.href = rawUrl;
  download.download = path.split("/").pop() || "download";
  download.textContent = "Download raw";
  actions.append(download);
  const viewer = document.createElement("pre");
  viewer.className = "blob-viewer";
  viewer.textContent = "Loading file…";
  dashboard.append(actions, viewer);
  try {
    const response = await fetch(rawUrl);
    if (!response.ok) throw new Error(`blob returned ${response.status}`);
    const contentType = response.headers.get("content-type") || "";
    const contentLength = Number(response.headers.get("content-length") || 0);
    const binary = /(?:octet-stream|application\/(?:pdf|zip)|image\/)/i.test(contentType)
      || /^(?:audio|video|font)\//i.test(contentType);
    if (binary || contentLength > 1024 * 1024) {
      viewer.className = "blob-viewer blob-fallback muted-message";
      viewer.textContent = binary
        ? "This binary file is available through Download raw."
        : "This file is too large to preview. Use Download raw instead.";
      return;
    }
    renderSourceSafe(viewer, await response.text(), path);
  } catch (_error) {
    viewer.className = "blob-viewer muted-message";
    viewer.textContent = "This file could not be loaded.";
  }
}

async function showCommitHistory(repository, branch) {
  pageTitle.textContent = "Commit history";
  pageLede.textContent = `${repository} · ${branch}`;
  dashboard.replaceChildren();
  const list = document.createElement("ol");
  list.className = "commit-list";
  const loading = document.createElement("li");
  loading.className = "muted-message";
  loading.textContent = "Loading commits…";
  list.append(loading);
  dashboard.append(list);
  try {
    const response = await fetch(
      `/api/repos/${encodeURIComponent(repository)}/commits?ref=${encodeURIComponent(branch)}`,
    );
    if (!response.ok) throw new Error(`commits returned ${response.status}`);
    const commits = await response.json();
    list.replaceChildren();
    if (!Array.isArray(commits) || !commits.length) {
      const empty = document.createElement("li");
      empty.className = "muted-message";
      empty.textContent = "No commits are available for this reference.";
      list.append(empty);
      return;
    }
    commits.forEach((commit) => {
      const item = document.createElement("li");
      const link = document.createElement("a");
      link.href = `/ui/repos/${encodeURIComponent(repository)}/commit/${encodeURIComponent(commit.oid)}`;
      link.textContent = commit.message || commit.oid;
      item.append(link);
      if (commit.author) {
        const author = document.createElement("span");
        author.className = "entry-summary";
        author.textContent = ` — ${commit.author}`;
        item.append(author);
      }
      list.append(item);
    });
  } catch (_error) {
    list.replaceChildren();
    const failure = document.createElement("li");
    failure.className = "muted-message";
    failure.textContent = "Commit history could not be loaded.";
    list.append(failure);
  }
}

async function showCommitDetail(repository, oid) {
  pageTitle.textContent = "Commit detail";
  pageLede.textContent = `${repository} · ${oid}`;
  dashboard.replaceChildren();
  const panel = document.createElement("article");
  panel.className = "commit-detail";
  panel.textContent = "Loading commit…";
  dashboard.append(panel);
  try {
    const response = await fetch(
      `/api/repos/${encodeURIComponent(repository)}/commits/${encodeURIComponent(oid)}`,
    );
    if (!response.ok) throw new Error(`commit returned ${response.status}`);
    const commit = await response.json();
    panel.replaceChildren();
    const hash = document.createElement("code");
    hash.textContent = commit.oid || oid;
    const message = document.createElement("pre");
    message.className = "commit-message";
    message.textContent = commit.message || "No commit message.";
    panel.append(hash, message);
    if (commit.author) {
      const author = document.createElement("p");
      author.className = "entry-summary";
      author.textContent = `Author: ${commit.author}`;
      panel.append(author);
    }
    if (Array.isArray(commit.parents) && commit.parents.length) {
      const parents = document.createElement("p");
      parents.className = "entry-summary";
      parents.textContent = "Parents: ";
      commit.parents.forEach((parent, index) => {
        const link = document.createElement("a");
        link.href = `/ui/repos/${encodeURIComponent(repository)}/commit/${encodeURIComponent(parent)}`;
        link.textContent = parent;
        parents.append(index ? ", " : "", link);
      });
      panel.append(parents);
    }
  } catch (_error) {
    panel.className = "commit-detail muted-message";
    panel.textContent = "This commit could not be loaded.";
  }
}
