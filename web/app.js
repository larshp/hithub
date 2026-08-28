const headerStatus = document.querySelector("#header-status");
const serviceStatus = document.querySelector("#service-status");
const dashboard = document.querySelector("#repository-dashboard");
const pageTitle = document.querySelector("#page-title");
const pageLede = document.querySelector(".lede");
const panel = document.querySelector(".content-panel");
const panelHeading = document.querySelector(".panel-heading");
const createRepositoryLink = document.querySelector(".page-intro .button");

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
const pullRequestRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/pulls\/([^/]+)$/,
);
const pullRequestCreateRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/pulls\/new$/,
);
const issueListRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/issues$/,
);
const issueRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/issues\/([^/]+)$/,
);
const issueCreateRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/issues\/new$/,
);
const auditRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/audit$/,
);
if (window.location.pathname !== "/") {
  createRepositoryLink.hidden = true;
  panelHeading.hidden = true;
  panel.removeAttribute("aria-labelledby");
  panel.classList.add("page-content-panel");
  dashboard.className = "page-dashboard";
}
if (window.location.pathname === "/ui/create") showCreateForm();
else if (pullRequestCreateRoute) showCreatePullRequest(
  decodeURIComponent(pullRequestCreateRoute[1]),
);
else if (issueCreateRoute) showCreateIssue(
  decodeURIComponent(issueCreateRoute[1]),
);
else if (issueRoute) showIssue(
  decodeURIComponent(issueRoute[1]), decodeURIComponent(issueRoute[2]),
);
else if (issueListRoute) showIssues(decodeURIComponent(issueListRoute[1]));
else if (auditRoute) showAudit(decodeURIComponent(auditRoute[1]));
else if (pullRequestRoute) showPullRequest(
  decodeURIComponent(pullRequestRoute[1]), decodeURIComponent(pullRequestRoute[2]),
);
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
  dashboard.className = "repository-overview";
  dashboard.replaceChildren();
  const loading = document.createElement("p");
  loading.className = "muted-message";
  loading.textContent = "Loading repository…";
  dashboard.append(loading);
  try {
    const encoded = encodeURIComponent(name);
    const [repositoryResponse, branchesResponse, tagsResponse, activityResponse] = await Promise.all([
      fetch(`/api/repos/${encoded}`),
      fetch(`/api/repos/${encoded}/branches`),
      fetch(`/api/repos/${encoded}/tags`),
      fetch(`/api/repos/${encoded}/activity`),
    ]);
    if (!repositoryResponse.ok) throw new Error("repository not found");
    const repository = await repositoryResponse.json();
    const branches = branchesResponse.ok ? await branchesResponse.json() : [];
    const tags = tagsResponse.ok ? await tagsResponse.json() : [];
    const activity = activityResponse.ok ? await activityResponse.json() : [];
    dashboard.replaceChildren();
    const header = document.createElement("div");
    header.className = "overview-header";
    const cloneInfo = document.createElement("div");
    cloneInfo.className = "clone-info";
    const cloneLabel = document.createElement("span");
    cloneLabel.className = "overview-label";
    cloneLabel.textContent = "Clone with Git";
    const clone = document.createElement("code");
    clone.textContent = `${window.location.origin}/git/${repository.name}.git`;
    cloneInfo.append(cloneLabel, clone);
    const actions = document.createElement("div");
    actions.className = "overview-actions";
    const issueLink = document.createElement("a");
    issueLink.className = "button";
    issueLink.href = `/ui/repos/${encoded}/issues`;
    issueLink.textContent = "Issues";
    const auditLink = document.createElement("a");
    auditLink.className = "button";
    auditLink.href = `/ui/repos/${encoded}/audit`;
    auditLink.textContent = "Audit";
    actions.append(issueLink, auditLink);
    header.append(cloneInfo, actions);
    const details = document.createElement("div");
    details.className = "overview-meta";
    for (const [label, value] of [
      ["Default branch", repository.default_branch],
      ["Version", String(repository.version)],
      ["Branches", String(branches.length)],
      ["Tags", String(tags.length)],
    ]) {
      const stat = document.createElement("div");
      stat.className = "overview-stat";
      const statLabel = document.createElement("span");
      statLabel.className = "overview-label";
      statLabel.textContent = label;
      const statValue = document.createElement("strong");
      statValue.textContent = value;
      stat.append(statLabel, statValue);
      details.append(stat);
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
    const activityPanel = document.createElement("section");
    activityPanel.className = "readme-panel activity-panel";
    const activityTitle = document.createElement("h3");
    activityTitle.textContent = "Recent activity";
    const activityList = document.createElement("ul");
    activityList.className = "activity-list";
    if (!activity.length) {
      const empty = document.createElement("li");
      empty.className = "muted-message";
      empty.textContent = "No activity yet.";
      activityList.append(empty);
    }
    for (const entry of activity) {
      const item = document.createElement("li");
      const summary = document.createElement("span");
      summary.textContent = `${entry.actor || "Unknown actor"} · ${entry.action} · ${entry.occurred_at}`;
      item.append(summary);
      if (entry.subject_type === "issue") {
        const link = document.createElement("a");
        link.href = `/ui/repos/${encoded}/issues/${encodeURIComponent(entry.subject_id)}`;
        link.textContent = `Issue ${entry.subject_id}`;
        item.append(" ", link);
      }
      activityList.append(item);
    }
    activityPanel.append(activityTitle, activityList);
    dashboard.append(header, details, selector, referenceColumns, readme, activityPanel);
  } catch (_error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "This repository could not be loaded.";
    dashboard.append(failure);
  }
}

async function showPullRequest(repository, id) {
  pageTitle.textContent = `Pull request ${id}`;
  pageLede.textContent = `${repository} · review and update pull-request state.`;
  dashboard.replaceChildren();
  const loading = document.createElement("p");
  loading.className = "muted-message";
  loading.textContent = "Loading pull request…";
  dashboard.append(loading);
  try {
    const encodedRepository = encodeURIComponent(repository);
    const encodedId = encodeURIComponent(id);
    const response = await fetch(
      `/api/repos/${encodedRepository}/pulls/${encodedId}`,
      {headers: {accept: "application/json"}},
    );
    if (!response.ok) throw new Error(`pull request returned ${response.status}`);
    const pullRequest = await response.json();
    dashboard.replaceChildren();
    const panel = document.createElement("article");
    panel.className = "pull-request-panel";
    const heading = document.createElement("h2");
    heading.textContent = `Pull request ${pullRequest.id}`;
    const state = document.createElement("p");
    state.className = "status-pill";
    state.textContent = pullRequest.state;
    state.setAttribute("aria-label", `State: ${pullRequest.state}`);
    const mergeability = pullRequest.mergeability || "unknown";
    const mergeExplanation = {
      clean: "No conflicting changes were detected.",
      conflicting: "Resolve the conflicting files before merging.",
      stale: "The source or target reference moved; refresh the comparison.",
      blocked: "Branch protection or required reviews are blocking the merge.",
      unknown: "Mergeability has not been calculated yet.",
    }[mergeability] || "Mergeability could not be determined.";
    const mergeStatus = document.createElement("p");
    mergeStatus.className = "merge-status";
    mergeStatus.textContent = `Mergeability: ${mergeability}. ${mergeExplanation}`;
    mergeStatus.setAttribute("role", "status");
    const details = document.createElement("dl");
    details.className = "repository-meta";
    for (const [label, value] of [
      ["Source", pullRequest.source_ref],
      ["Target", pullRequest.target_ref],
      ["Base", pullRequest.base_oid],
      ["Head", pullRequest.head_oid],
      ["Version", String(pullRequest.version)],
    ]) {
      const term = document.createElement("dt");
      term.textContent = label;
      const detail = document.createElement("dd");
      detail.textContent = value;
      details.append(term, detail);
    }
    const actions = document.createElement("div");
    actions.className = "pull-request-actions";
    const nextState = {draft: "open", open: "closed", closed: "open"}[pullRequest.state];
    if (nextState) {
      const action = document.createElement("button");
      action.className = "button";
      action.type = "button";
      action.textContent = nextState === "open"
        ? "Ready for review" : "Close pull request";
      action.addEventListener("click", async () => {
        action.disabled = true;
        try {
          const update = await fetch(
            `/api/repos/${encodedRepository}/pulls/${encodedId}`,
            {
              method: "PATCH",
              headers: {
                "content-type": "application/json",
                "if-match": `"${pullRequest.version}"`,
              },
              body: JSON.stringify({state: nextState}),
            },
          );
          if (!update.ok) throw new Error(`pull request update returned ${update.status}`);
          await showPullRequest(repository, id);
        } catch (_error) {
          action.disabled = false;
          action.textContent = "Update failed; try again";
        }
      });
      actions.append(action);
    }
    if (pullRequest.state === "open") {
      const mergeAction = document.createElement("button");
      mergeAction.className = "button";
      mergeAction.type = "button";
      mergeAction.textContent = "Merge pull request";
      mergeAction.addEventListener("click", async () => {
        mergeAction.disabled = true;
        try {
          const merge = await fetch(
            `/api/repos/${encodedRepository}/pulls/${encodedId}/merge`,
            {
              method: "PUT",
              headers: {"content-type": "application/json"},
              body: JSON.stringify({
                expected_head_oid: pullRequest.head_oid,
                clean: true,
              }),
            },
          );
          if (!merge.ok) throw new Error(`merge returned ${merge.status}`);
          await showPullRequest(repository, id);
        } catch (_error) {
          mergeAction.disabled = false;
          mergeAction.textContent = "Merge failed; try again";
        }
      });
      actions.append(mergeAction);
    }
    panel.append(heading, state, mergeStatus, details, actions);
    dashboard.append(panel);
  } catch (_error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "This pull request could not be loaded.";
    dashboard.append(failure);
  }
}

async function showIssues(repository) {
  pageTitle.textContent = "Issues";
  pageLede.textContent = `${repository} · track work and discussions.`;
  dashboard.replaceChildren();
  const create = document.createElement("a");
  create.className = "button";
  create.href = `/ui/repos/${encodeURIComponent(repository)}/issues/new`;
  create.textContent = "New issue";
  dashboard.append(create);
  try {
    const response = await fetch(
      `/api/repos/${encodeURIComponent(repository)}/issues`,
      {headers: {accept: "application/json"}},
    );
    if (!response.ok) throw new Error(`issues returned ${response.status}`);
    const issues = await response.json();
    const list = document.createElement("div");
    list.className = "issue-list";
    if (!issues.length) {
      const empty = document.createElement("p");
      empty.className = "muted-message";
      empty.textContent = "No issues yet.";
      list.append(empty);
    }
    for (const issue of issues) {
      const card = document.createElement("article");
      card.className = "issue-card";
      const heading = document.createElement("h2");
      const link = document.createElement("a");
      link.href = `/ui/repos/${encodeURIComponent(repository)}/issues/${encodeURIComponent(issue.id)}`;
      link.textContent = `${issue.title} #${issue.id}`;
      heading.append(link);
      const state = document.createElement("span");
      state.className = "status-pill";
      state.textContent = issue.state;
      const body = document.createElement("p");
      body.className = "issue-excerpt";
      body.textContent = issue.body || "No description.";
      card.append(heading, state, body);
      list.append(card);
    }
    dashboard.append(list);
  } catch (_error) {
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "Issues could not be loaded.";
    dashboard.append(failure);
  }
}

async function showAudit(repository) {
  pageTitle.textContent = "Repository audit";
  pageLede.textContent = `${repository} · durable events and request context.`;
  dashboard.replaceChildren();
  try {
    const response = await fetch(
      `/api/repos/${encodeURIComponent(repository)}/audit`,
      {headers: {accept: "application/json"}},
    );
    if (!response.ok) throw new Error(`audit returned ${response.status}`);
    const entries = await response.json();
    const list = document.createElement("div");
    list.className = "audit-list";
    if (!entries.length) {
      const empty = document.createElement("p");
      empty.className = "muted-message";
      empty.textContent = "No audit events yet.";
      list.append(empty);
    }
    for (const entry of entries) {
      const item = document.createElement("article");
      item.className = "audit-entry";
      const heading = document.createElement("h2");
      heading.textContent = entry.action;
      const metadata = document.createElement("dl");
      metadata.className = "repository-meta";
      for (const [label, value] of [
        ["Actor", entry.actor || "Not supplied"],
        ["Subject", `${entry.subject_type}/${entry.subject_id}`],
        ["Occurred", entry.occurred_at],
        ["Correlation", entry.correlation_id || "Not supplied"],
        ["Event ID", entry.event_id],
        ["Details", entry.details || ""],
      ]) {
        const term = document.createElement("dt");
        term.textContent = label;
        const detail = document.createElement("dd");
        detail.textContent = value;
        metadata.append(term, detail);
      }
      item.append(heading, metadata);
      list.append(item);
    }
    dashboard.append(list);
  } catch (_error) {
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "Audit events could not be loaded.";
    dashboard.append(failure);
  }
}

async function showCreateIssue(repository) {
  pageTitle.textContent = "Open an issue";
  pageLede.textContent = `${repository} · describe a task, bug, or discussion.`;
  dashboard.replaceChildren();
  const form = document.createElement("form");
  form.className = "repository-form issue-form";
  const fields = [
    ["id", "Issue ID", `issue-${Date.now()}`, "input"],
    ["title", "Title", "", "input"],
    ["body", "Description", "", "textarea"],
  ];
  for (const [name, labelText, value, kind] of fields) {
    const label = document.createElement("label");
    label.htmlFor = `issue-${name}`;
    label.textContent = labelText;
    const input = document.createElement(kind);
    input.id = `issue-${name}`;
    input.name = name;
    input.value = value;
    input.required = name !== "body";
    input.maxLength = name === "title" ? 255 : name === "id" ? 36 : 10000;
    if (kind === "textarea") input.rows = 8;
    form.append(label, input);
  }
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Create issue";
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  form.append(submit, status);
  dashboard.append(form);
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    submit.disabled = true;
    status.textContent = "Creating issue…";
    try {
      const response = await fetch(
        `/api/repos/${encodeURIComponent(repository)}/issues`,
        {
          method: "POST",
          headers: {"content-type": "application/json"},
          body: JSON.stringify({
            id: form.elements.id.value,
            title: form.elements.title.value,
            body: form.elements.body.value,
          }),
        },
      );
      if (!response.ok) throw new Error(`issue create returned ${response.status}`);
      const issue = await response.json();
      window.location.href = `/ui/repos/${encodeURIComponent(repository)}/issues/${encodeURIComponent(issue.id)}`;
    } catch (_error) {
      submit.disabled = false;
      status.className = "form-status is-error";
      status.textContent = "Issue could not be created. Try again.";
    }
  });
}

async function showIssue(repository, id) {
  pageTitle.textContent = `Issue ${id}`;
  pageLede.textContent = `${repository} · update status and discuss the issue.`;
  dashboard.replaceChildren();
  const loading = document.createElement("p");
  loading.className = "muted-message";
  loading.textContent = "Loading issue…";
  dashboard.append(loading);
  try {
    const encodedRepository = encodeURIComponent(repository);
    const encodedId = encodeURIComponent(id);
    const [issueResponse, commentsResponse] = await Promise.all([
      fetch(`/api/repos/${encodedRepository}/issues/${encodedId}`),
      fetch(`/api/repos/${encodedRepository}/issues/${encodedId}/comments`),
    ]);
    if (!issueResponse.ok) throw new Error("issue not found");
    const issue = await issueResponse.json();
    const comments = commentsResponse.ok ? await commentsResponse.json() : [];
    dashboard.replaceChildren();
    const panel = document.createElement("article");
    panel.className = "issue-panel";
    const heading = document.createElement("h2");
    heading.textContent = `${issue.title} #${issue.id}`;
    const state = document.createElement("p");
    state.className = "status-pill";
    state.textContent = issue.state;
    state.setAttribute("aria-label", `State: ${issue.state}`);
    const body = document.createElement("div");
    body.className = "issue-body readme-content";
    body.append(...renderMarkdownSafe(issue.body).childNodes);
    const details = document.createElement("dl");
    details.className = "repository-meta";
    for (const [label, value] of [
      ["Opened by", issue.actor || "Runtime actor unavailable"],
      ["Created", issue.created_at],
      ["Updated", issue.updated_at],
      ["Version", String(issue.version)],
    ]) {
      const term = document.createElement("dt");
      term.textContent = label;
      const detail = document.createElement("dd");
      detail.textContent = value;
      details.append(term, detail);
    }
    const actions = document.createElement("div");
    actions.className = "pull-request-actions";
    const stateAction = document.createElement("button");
    stateAction.className = "button";
    stateAction.type = "button";
    const nextState = issue.state === "open" ? "closed" : "open";
    stateAction.textContent = nextState === "closed" ? "Close issue" : "Reopen issue";
    stateAction.addEventListener("click", async () => {
      stateAction.disabled = true;
      try {
        const response = await fetch(
          `/api/repos/${encodedRepository}/issues/${encodedId}`,
          {
            method: "PATCH",
            headers: {
              "content-type": "application/json",
              "if-match": `"${issue.version}"`,
            },
            body: JSON.stringify({state: nextState}),
          },
        );
        if (!response.ok) throw new Error("issue state update failed");
        await showIssue(repository, id);
      } catch (_error) {
        stateAction.disabled = false;
        stateAction.textContent = "Update failed; try again";
      }
    });
    actions.append(stateAction);
    panel.append(heading, state, body, details, actions);

    const edit = document.createElement("form");
    edit.className = "repository-form issue-form";
    const titleLabel = document.createElement("label");
    titleLabel.htmlFor = "issue-edit-title";
    titleLabel.textContent = "Edit title";
    const titleInput = document.createElement("input");
    titleInput.id = "issue-edit-title";
    titleInput.value = issue.title;
    titleInput.required = true;
    titleInput.maxLength = 255;
    const bodyLabel = document.createElement("label");
    bodyLabel.htmlFor = "issue-edit-body";
    bodyLabel.textContent = "Edit description";
    const bodyInput = document.createElement("textarea");
    bodyInput.id = "issue-edit-body";
    bodyInput.rows = 6;
    bodyInput.value = issue.body;
    const editButton = document.createElement("button");
    editButton.className = "button";
    editButton.type = "submit";
    editButton.textContent = "Save issue";
    const editStatus = document.createElement("p");
    editStatus.className = "form-status";
    editStatus.setAttribute("role", "status");
    edit.append(titleLabel, titleInput, bodyLabel, bodyInput, editButton, editStatus);
    edit.addEventListener("submit", async (event) => {
      event.preventDefault();
      editButton.disabled = true;
      try {
        const response = await fetch(
          `/api/repos/${encodedRepository}/issues/${encodedId}`,
          {
            method: "PATCH",
            headers: {
              "content-type": "application/json",
              "if-match": `"${issue.version}"`,
            },
            body: JSON.stringify({title: titleInput.value, body: bodyInput.value}),
          },
        );
        if (!response.ok) throw new Error("issue edit failed");
        await showIssue(repository, id);
      } catch (_error) {
        editButton.disabled = false;
        editStatus.className = "form-status is-error";
        editStatus.textContent = "Issue could not be updated.";
      }
    });

    const discussion = document.createElement("section");
    discussion.className = "issue-comments";
    const discussionHeading = document.createElement("h2");
    discussionHeading.textContent = "Discussion";
    const commentList = document.createElement("div");
    commentList.className = "issue-comment-list";
    if (!comments.length) {
      const empty = document.createElement("p");
      empty.className = "muted-message";
      empty.textContent = "No comments yet.";
      commentList.append(empty);
    }
    for (const comment of comments) {
      const item = document.createElement("article");
      item.className = "issue-comment";
      const meta = document.createElement("p");
      meta.className = "entry-summary";
      meta.textContent = `${comment.actor} · ${comment.created_at}`;
      const text = document.createElement("p");
      text.textContent = comment.body;
      item.append(meta, text);
      commentList.append(item);
    }
    const commentForm = document.createElement("form");
    commentForm.className = "repository-form issue-form";
    const commentId = document.createElement("input");
    commentId.placeholder = "Comment ID";
    commentId.required = true;
    const commentBody = document.createElement("textarea");
    commentBody.placeholder = "Add a comment";
    commentBody.required = true;
    commentBody.rows = 4;
    const commentButton = document.createElement("button");
    commentButton.className = "button";
    commentButton.type = "submit";
    commentButton.textContent = "Add comment";
    const commentStatus = document.createElement("p");
    commentStatus.className = "form-status";
    commentForm.append(commentId, commentBody, commentButton, commentStatus);
    commentForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      commentButton.disabled = true;
      try {
        const response = await fetch(
          `/api/repos/${encodedRepository}/issues/${encodedId}/comments`,
          {
            method: "POST",
            headers: {"content-type": "application/json"},
            body: JSON.stringify({id: commentId.value, body: commentBody.value}),
          },
        );
        if (!response.ok) throw new Error("comment failed");
        await showIssue(repository, id);
      } catch (_error) {
        commentButton.disabled = false;
        commentStatus.className = "form-status is-error";
        commentStatus.textContent = "Comment could not be added.";
      }
    });
    discussion.append(discussionHeading, commentList, commentForm);
    dashboard.append(panel, edit, discussion);
  } catch (_error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "This issue could not be loaded.";
    dashboard.append(failure);
  }
}

async function showCreatePullRequest(repository) {
  pageTitle.textContent = "Open a pull request";
  pageLede.textContent = `${repository} · compare a source ref with a target ref.`;
  dashboard.replaceChildren();
  const form = document.createElement("form");
  form.className = "repository-form pull-request-form";
  const query = new URLSearchParams(window.location.search);
  const fields = [
    ["id", "Pull request ID", query.get("id") || `pull-${Date.now()}`],
    ["source_ref", "Source ref", query.get("source") || "refs/heads/feature"],
    ["target_ref", "Target ref", query.get("target") || "refs/heads/main"],
    ["base_oid", "Base object ID", query.get("base") || "base"],
    ["head_oid", "Head object ID", query.get("head") || "head"],
  ];
  for (const [name, labelText, value] of fields) {
    const label = document.createElement("label");
    label.htmlFor = `pull-${name}`;
    label.textContent = labelText;
    const input = document.createElement("input");
    input.id = `pull-${name}`;
    input.name = name;
    input.value = value;
    input.required = true;
    input.maxLength = name.endsWith("_ref") ? 160 : 64;
    form.append(label, input);
  }
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Create pull request";
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  form.append(submit, status);
  dashboard.append(form);
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    submit.disabled = true;
    status.textContent = "Creating pull request…";
    try {
      const response = await fetch(
        `/api/repos/${encodeURIComponent(repository)}/pulls`,
        {
          method: "POST",
          headers: {"content-type": "application/json"},
          body: JSON.stringify(Object.fromEntries(new FormData(form))),
        },
      );
      const body = await response.json();
      if (!response.ok) throw new Error(body.detail || "create failed");
      window.location.href = `/ui/repos/${encodeURIComponent(repository)}/pulls/${encodeURIComponent(body.id)}`;
    } catch (error) {
      submit.disabled = false;
      status.className = "form-status is-error";
      status.textContent = error.message || "Pull request could not be created.";
    }
  });
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
        const mergeButton = document.createElement("button");
        mergeButton.className = "button merge-button";
        mergeButton.type = "button";
        mergeButton.textContent = "Merge pull request";
        mergeButton.disabled = true;
        mergeButton.setAttribute("aria-describedby", "compare-status");
        status.id = "compare-status";
        status.textContent = `${base.value} compared with ${head.value}. Open a pull request to enable merging.`;
        dashboard.append(mergeButton);
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
