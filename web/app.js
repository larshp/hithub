const dashboard = document.querySelector("#repository-dashboard");
const pageTitle = document.querySelector("#page-title");
const pageLede = document.querySelector(".lede");
const pageIntro = document.querySelector(".page-intro");
const repositoryNavigation = document.querySelector("#repository-navigation");
const panel = document.querySelector(".content-panel");
const createRepositoryLink = document.querySelector(".page-intro .button");
const mobileMenuToggle = document.querySelector(".mobile-menu-toggle");
const primaryNavigation = document.querySelector("#primary-navigation");
const globalSearchInput = document.querySelector("#global-search-input");

const iconPaths = {
  repository: "M2 2.5A2.5 2.5 0 0 1 4.5 0h8.75a.75.75 0 0 1 .75.75v12.5a.75.75 0 0 1-.75.75H4.5A2.5 2.5 0 0 1 2 11.5Zm1.5 0v9A1 1 0 0 0 4.5 12.5h8V1.5h-8a1 1 0 0 0-1 1Zm2 1.25A.75.75 0 0 1 6.25 3h4.5a.75.75 0 0 1 0 1.5h-4.5a.75.75 0 0 1-.75-.75Z",
  code: "M4.72 3.22a.75.75 0 0 1 1.06 1.06L2.06 8l3.72 3.72a.75.75 0 1 1-1.06 1.06l-4.25-4.25a.75.75 0 0 1 0-1.06Zm6.56 0a.75.75 0 0 0-1.06 1.06L13.94 8l-3.72 3.72a.75.75 0 1 0 1.06 1.06l4.25-4.25a.75.75 0 0 0 0-1.06Z",
  issue: "M8 9.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3ZM8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0Zm0 1.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13Z",
  pull: "M1.5 3.25a2.25 2.25 0 1 1 3 2.122v5.256a2.251 2.251 0 1 1-1.5 0V5.372A2.25 2.25 0 0 1 1.5 3.25Zm10.75 7.5a.75.75 0 0 1-.75-.75V5.56L9.53 7.53a.75.75 0 0 1-1.06-1.06l3.25-3.25a.75.75 0 0 1 1.06 0l3.25 3.25a.75.75 0 0 1-1.06 1.06L13 5.56V10a.75.75 0 0 1-.75.75Z",
  audit: "M8 0c.69 0 1.765.311 2.91.695 1.18.395 2.372.836 3.33 1.187a.75.75 0 0 1 .49.704v4.985c0 3.925-2.296 6.76-6.432 8.349a.75.75 0 0 1-.536 0C3.63 14.331 1.27 11.496 1.27 7.571V2.586a.75.75 0 0 1 .49-.704A71.7 71.7 0 0 1 5.09.695C6.235.31 7.31 0 8 0Zm0 1.5c-.45 0-1.39.25-2.433.6a68.2 68.2 0 0 0-2.797.985v4.486c0 3.15 1.785 5.438 5.23 6.842 3.445-1.404 5.23-3.693 5.23-6.842V3.085a68.2 68.2 0 0 0-2.797-.984C9.39 1.75 8.45 1.5 8 1.5Z",
  more: "M3.75 8a1.25 1.25 0 1 1-2.5 0 1.25 1.25 0 0 1 2.5 0Zm5.5 0a1.25 1.25 0 1 1-2.5 0 1.25 1.25 0 0 1 2.5 0Zm5.5 0a1.25 1.25 0 1 1-2.5 0 1.25 1.25 0 0 1 2.5 0Z",
  copy: "M0 6.75C0 5.784.784 5 1.75 5h6.5C9.216 5 10 5.784 10 6.75v7.5A1.75 1.75 0 0 1 8.25 16h-6.5A1.75 1.75 0 0 1 0 14.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h6.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Zm4-6.5h6.5C13.216 0 14 .784 14 1.75v7.5A1.75 1.75 0 0 1 12.25 11h-.5a.75.75 0 0 1 0-1.5h.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25h-6.5a.25.25 0 0 0-.25.25v.5a.75.75 0 0 1-1.5 0v-.5C4 .784 4.784 0 5.75 0Z",
  branch: "M9.5 3.25a2.25 2.25 0 1 1 3 2.122V6A2.5 2.5 0 0 1 10 8.5H6a1 1 0 0 0-1 1v1.128a2.251 2.251 0 1 1-1.5 0V5.372a2.25 2.25 0 1 1 1.5 0v1.836A2.493 2.493 0 0 1 6 7h4a1 1 0 0 0 1-1v-.628A2.25 2.25 0 0 1 9.5 3.25Zm-6 0a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0Zm8.25-.75a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5ZM4.25 12a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Z",
  tag: "M1 7.775V2.75C1 1.784 1.784 1 2.75 1h5.025c.464 0 .91.184 1.238.513l6.25 6.25a1.75 1.75 0 0 1 0 2.474l-5.026 5.026a1.75 1.75 0 0 1-2.474 0l-6.25-6.25A1.75 1.75 0 0 1 1 7.775Zm1.5 0c0 .066.026.13.073.177l6.25 6.25a.25.25 0 0 0 .354 0l5.025-5.025a.25.25 0 0 0 0-.354l-6.25-6.25a.25.25 0 0 0-.177-.073H2.75a.25.25 0 0 0-.25.25ZM6 5a1 1 0 1 1 0 2 1 1 0 0 1 0-2Z",
  check: "M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z",
  search: "M10.68 11.74a6 6 0 0 1-7.922-8.982 6 6 0 0 1 8.982 7.922l3.04 3.04a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215ZM11.5 7a4.499 4.499 0 1 0-8.997 0A4.499 4.499 0 0 0 11.5 7Z",
  close: "M3.72 3.72a.75.75 0 0 1 1.06 0L8 6.94l3.22-3.22a.749.749 0 0 1 1.275.326.749.749 0 0 1-.215.734L9.06 8l3.22 3.22a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215L8 9.06l-3.22 3.22a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042L6.94 8 3.72 4.78a.75.75 0 0 1 0-1.06Z",
  plus: "M7.75 2a.75.75 0 0 1 .75.75V7h4.25a.75.75 0 0 1 0 1.5H8.5v4.25a.75.75 0 0 1-1.5 0V8.5H2.75a.75.75 0 0 1 0-1.5H7V2.75A.75.75 0 0 1 7.75 2Z",
  pencil: "M11.013 1.427a1.75 1.75 0 0 1 2.474 0l1.086 1.086a1.75 1.75 0 0 1 0 2.474l-8.61 8.61c-.21.21-.47.364-.756.445l-3.251.93a.75.75 0 0 1-.927-.928l.929-3.25c.081-.286.235-.547.445-.758l8.61-8.61Zm.176 4.823L9.75 4.81l-6.286 6.287a.253.253 0 0 0-.064.108l-.558 1.953 1.953-.558a.253.253 0 0 0 .108-.064Zm1.238-3.763a.25.25 0 0 0-.354 0L10.811 3.75l1.439 1.44 1.263-1.263a.25.25 0 0 0 0-.354Z",
};

function interfaceIcon(name, className = "octicon") {
  const namespace = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(namespace, "svg");
  svg.classList.add(className);
  svg.setAttribute("viewBox", "0 0 16 16");
  svg.setAttribute("width", "16");
  svg.setAttribute("height", "16");
  svg.setAttribute("aria-hidden", "true");
  const path = document.createElementNS(namespace, "path");
  path.setAttribute("d", iconPaths[name]);
  svg.append(path);
  return svg;
}

mobileMenuToggle?.addEventListener("click", () => {
  const open = mobileMenuToggle.getAttribute("aria-expanded") !== "true";
  mobileMenuToggle.setAttribute("aria-expanded", String(open));
  mobileMenuToggle.setAttribute("aria-label", open ? "Close navigation" : "Open navigation");
  primaryNavigation.classList.toggle("is-open", open);
});

const initialSearch = new URLSearchParams(window.location.search).get("q") || "";
if (globalSearchInput) globalSearchInput.value = initialSearch;
document.addEventListener("keydown", (event) => {
  if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return;
  const typing = ["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName);
  if (typing) return;
  event.preventDefault();
  globalSearchInput?.focus();
});

function repositoryRow(repository) {
  const row = document.createElement("article");
  row.className = "repository-row";
  const main = document.createElement("div");
  main.className = "repository-row-main";
  const title = document.createElement("h2");
  const link = document.createElement("a");
  link.href = `/ui/repos/${encodeURIComponent(repository.name)}`;
  link.textContent = repository.name;
  title.append(link);
  const description = document.createElement("p");
  description.textContent = repository.description || "No description yet.";
  main.append(title, description);
  const branch = document.createElement("span");
  branch.className = "repository-row-branch";
  branch.append(interfaceIcon("pull"), document.createTextNode(
    `Default branch ${shortReference(repository.default_branch)}`,
  ));
  row.append(main, branch);
  return row;
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

function generateInternalId() {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 14)}`;
}

function shortReference(reference) {
  return String(reference || "").replace(/^refs\/(heads|tags)\//, "") || "unknown";
}

function formatRelativeTimestamp(value) {
  const date = commitTimestampDate(value);
  if (!date) return value ? String(value) : "recently";
  const elapsed = date.getTime() - Date.now();
  const units = [
    ["year", 31_536_000_000],
    ["month", 2_592_000_000],
    ["day", 86_400_000],
    ["hour", 3_600_000],
    ["minute", 60_000],
  ];
  const formatter = new Intl.RelativeTimeFormat(undefined, {numeric: "auto"});
  for (const [unit, milliseconds] of units) {
    if (Math.abs(elapsed) >= milliseconds) {
      return formatter.format(Math.round(elapsed / milliseconds), unit);
    }
  }
  return "just now";
}

function createAvatar(actor) {
  const avatar = document.createElement("span");
  avatar.className = "avatar";
  avatar.setAttribute("aria-hidden", "true");
  avatar.textContent = String(actor || "H").trim().charAt(0).toLocaleUpperCase() || "H";
  return avatar;
}

function createStateBadge(state, kind = "issue") {
  const badge = document.createElement("span");
  badge.className = `state-badge is-${state}`;
  badge.setAttribute("aria-label", `State: ${state}`);
  badge.append(interfaceIcon(kind === "pull" ? "pull" : "issue"));
  const label = document.createElement("span");
  label.textContent = state === "draft" ? "Draft" : state === "closed" ? "Closed" : "Open";
  badge.append(label);
  return badge;
}

function createWorkList({items, kind, createHref, renderRow}) {
  const wrapper = document.createElement("section");
  wrapper.className = "work-list-shell";
  const searchRow = document.createElement("div");
  searchRow.className = "work-search-row";
  const searchLabel = document.createElement("label");
  searchLabel.className = "sr-only";
  searchLabel.htmlFor = `${kind}-filter`;
  searchLabel.textContent = `Search ${kind === "issue" ? "issues" : "pull requests"}`;
  const search = document.createElement("input");
  search.id = `${kind}-filter`;
  search.type = "search";
  search.placeholder = `Search ${kind === "issue" ? "issues" : "pull requests"}`;
  const create = document.createElement("a");
  create.className = "button";
  create.href = createHref;
  create.textContent = kind === "issue" ? "New issue" : "New pull request";
  searchRow.append(searchLabel, search, create);

  const panel = document.createElement("div");
  panel.className = "work-list-panel";
  const toolbar = document.createElement("div");
  toolbar.className = "work-list-toolbar";
  const openCount = items.filter((item) => item.state !== "closed").length;
  const closedCount = items.length - openCount;
  let selectedState = "open";
  const filters = document.createElement("div");
  filters.className = "work-state-filters";
  const filterButtons = [];
  for (const [state, count] of [["open", openCount], ["closed", closedCount]]) {
    const button = document.createElement("button");
    button.className = "work-state-filter";
    button.type = "button";
    button.dataset.state = state;
    button.setAttribute("aria-pressed", String(state === selectedState));
    button.textContent = `${count} ${state === "open" ? "Open" : "Closed"}`;
    filterButtons.push(button);
    filters.append(button);
  }
  const sort = document.createElement("select");
  sort.className = "work-sort";
  sort.setAttribute("aria-label", "Sort items");
  for (const [value, label] of [["newest", "Newest"], ["oldest", "Oldest"]]) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = label;
    sort.append(option);
  }
  toolbar.append(filters, sort);
  const list = document.createElement("div");
  list.className = `${kind === "issue" ? "issue" : "pull-request"}-list work-list`;

  const update = () => {
    const query = search.value.trim().toLocaleLowerCase();
    const matching = items
      .filter((item) => (selectedState === "open" ? item.state !== "closed" : item.state === "closed"))
      .filter((item) => JSON.stringify(item).toLocaleLowerCase().includes(query));
    if (sort.value === "oldest") matching.reverse();
    list.replaceChildren();
    if (!matching.length) {
      const empty = document.createElement("div");
      empty.className = "work-list-empty";
      const heading = document.createElement("h2");
      heading.textContent = query ? "No results matched your search" : `There aren't any ${selectedState} ${kind === "issue" ? "issues" : "pull requests"}.`;
      const hint = document.createElement("p");
      hint.textContent = query ? "Try a different search term or state." : `When there are, they'll appear here.`;
      empty.append(heading, hint);
      list.append(empty);
      return;
    }
    matching.forEach((item) => list.append(renderRow(item)));
  };
  filterButtons.forEach((button) => button.addEventListener("click", () => {
    selectedState = button.dataset.state;
    filterButtons.forEach((candidate) => candidate.setAttribute(
      "aria-pressed", String(candidate.dataset.state === selectedState),
    ));
    update();
  }));
  search.addEventListener("input", update);
  sort.addEventListener("change", update);
  update();
  panel.append(toolbar, list);
  wrapper.append(searchRow, panel);
  return wrapper;
}

function createMetadataSidebar(sections) {
  const sidebar = document.createElement("aside");
  sidebar.className = "metadata-sidebar";
  sidebar.setAttribute("aria-label", "Item metadata");
  sections.forEach(([title, value]) => {
    const section = document.createElement("section");
    const heading = document.createElement("h2");
    heading.textContent = title;
    section.append(heading);
    if (value instanceof Node) {
      section.append(value);
    } else {
      const content = document.createElement("p");
      content.textContent = value;
      section.append(content);
    }
    sidebar.append(section);
  });
  return sidebar;
}

function createMetadataList(items, emptyMessage) {
  if (!items.length) {
    const empty = document.createElement("p");
    empty.className = "muted-message";
    empty.textContent = emptyMessage;
    return empty;
  }
  const list = document.createElement("ul");
  list.className = "metadata-list";
  for (const item of items) {
    const entry = document.createElement("li");
    entry.append(createAvatar(item.primary), document.createTextNode(item.primary));
    if (item.secondary) {
      const secondary = document.createElement("span");
      secondary.className = "metadata-note";
      secondary.textContent = item.secondary;
      entry.append(secondary);
    }
    list.append(entry);
  }
  return list;
}

function createTokenEditor(options) {
  const {name, values, emptyMessage, placeholder, onAdd, onRemove} = options;
  const wrapper = document.createElement("div");
  wrapper.className = "metadata-tokens";
  if (!values.length) {
    const empty = document.createElement("p");
    empty.className = "muted-message";
    empty.textContent = emptyMessage;
    wrapper.append(empty);
  } else {
    const list = document.createElement("ul");
    list.className = "token-list";
    for (const value of values) {
      const entry = document.createElement("li");
      entry.className = "token";
      const label = document.createElement("span");
      label.textContent = value;
      const remove = document.createElement("button");
      remove.className = "token-remove";
      remove.type = "button";
      remove.textContent = "×";
      remove.setAttribute("aria-label", `Remove ${name} ${value}`);
      remove.addEventListener("click", async () => {
        remove.disabled = true;
        await onRemove(value);
      });
      entry.append(label, remove);
      list.append(entry);
    }
    wrapper.append(list);
  }
  const form = document.createElement("form");
  form.className = "token-form";
  const label = document.createElement("label");
  const inputId = `add-${name}`;
  label.htmlFor = inputId;
  label.className = "sr-only";
  label.textContent = `Add ${name}`;
  const input = document.createElement("input");
  input.id = inputId;
  input.required = true;
  input.maxLength = 100;
  input.placeholder = placeholder;
  const submit = document.createElement("button");
  submit.className = "button button-secondary token-add";
  submit.type = "submit";
  submit.textContent = "Add";
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    submit.disabled = true;
    const added = await onAdd(input.value.trim());
    if (!added) {
      submit.disabled = false;
      status.className = "form-status is-error";
      status.textContent = `${input.value.trim()} could not be added.`;
    }
  });
  form.append(label, input, submit, status);
  wrapper.append(form);
  return wrapper;
}

async function loadRepositories() {
  try {
    const response = await fetch("/api/repos", {headers: {accept: "application/json"}});
    if (!response.ok) throw new Error(`repository list returned ${response.status}`);
    const repositories = await response.json();
    dashboard.replaceChildren();
    const query = initialSearch.trim().toLocaleLowerCase();
    const matchingRepositories = query
      ? repositories.filter((repository) => [repository.name, repository.description]
        .some((value) => String(value || "").toLocaleLowerCase().includes(query)))
      : repositories;
    if (!matchingRepositories.length) {
      const empty = document.createElement("p");
      empty.className = "muted-message";
      empty.textContent = query
        ? `No repositories match “${initialSearch.trim()}”.`
        : "No repositories yet. Create one to begin browsing.";
      dashboard.append(empty);
      return;
    }
    matchingRepositories.forEach((repository) => dashboard.append(repositoryRow(repository)));
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
const pullRequestListRoute = window.location.pathname.match(
  /^\/ui\/repos\/([^/]+)\/pulls$/,
);
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
const repositoryPageRoute = repositoryRoute || treeRoute || blobRoute || historyRoute
  || commitRoute || compareRoute || pullRequestListRoute || pullRequestRoute || pullRequestCreateRoute
  || issueListRoute || issueRoute || issueCreateRoute || auditRoute;

async function loadRepositoryTabCounts(repository, targets) {
  const encoded = encodeURIComponent(repository);
  await Promise.all(Object.entries(targets).map(async ([kind, target]) => {
    try {
      const response = await fetch(`/api/repos/${encoded}/${kind}`, {
        headers: {accept: "application/json"},
      });
      if (!response.ok) return;
      const items = await response.json();
      if (!Array.isArray(items)) return;
      target.textContent = String(items.filter((item) => item.state !== "closed").length);
      target.hidden = false;
    } catch (_error) {
      // Navigation remains fully usable when optional counts are unavailable.
    }
  }));
}

function showRepositoryNavigation(repository) {
  const encoded = encodeURIComponent(repository);
  repositoryNavigation.hidden = false;
  repositoryNavigation.replaceChildren();
  const inner = document.createElement("div");
  inner.className = "repository-navigation-inner";
  const identityRow = document.createElement("div");
  identityRow.className = "repository-identity-row";
  const identity = document.createElement("a");
  identity.className = "repository-identity";
  identity.href = `/ui/repos/${encoded}`;
  identity.append(interfaceIcon("repository"));
  const owner = document.createElement("span");
  owner.className = "repository-owner";
  owner.textContent = "HitHub";
  const separator = document.createElement("span");
  separator.className = "repository-separator";
  separator.textContent = "/";
  const name = document.createElement("strong");
  name.textContent = repository;
  identity.append(owner, separator, name);
  identityRow.append(identity);
  const tabs = [
    ["code", "Code", `/ui/repos/${encoded}`, repositoryRoute || treeRoute || blobRoute || historyRoute || commitRoute || compareRoute, ""],
    ["issue", "Issues", `/ui/repos/${encoded}/issues`, issueListRoute || issueRoute || issueCreateRoute, "issues"],
    ["pull", "Pull requests", `/ui/repos/${encoded}/pulls`, pullRequestListRoute || pullRequestRoute || pullRequestCreateRoute, "pulls"],
  ];
  const tabList = document.createElement("div");
  tabList.className = "repository-tabs";
  const countTargets = {};
  tabs.forEach(([icon, label, href, active, countKind]) => {
    const link = document.createElement("a");
    link.href = href;
    link.className = active ? "repository-tab is-active" : "repository-tab";
    if (active) link.setAttribute("aria-current", "page");
    link.append(interfaceIcon(icon), document.createTextNode(label));
    if (countKind) {
      const count = document.createElement("span");
      count.className = "repository-tab-count";
      count.hidden = true;
      link.append(count);
      countTargets[countKind] = count;
    }
    tabList.append(link);
  });
  const more = document.createElement("details");
  more.className = "repository-more";
  const moreSummary = document.createElement("summary");
  moreSummary.className = auditRoute ? "repository-tab is-active" : "repository-tab";
  moreSummary.append(interfaceIcon("more"), document.createTextNode("More"));
  const moreMenu = document.createElement("div");
  moreMenu.className = "repository-more-menu";
  const auditLink = document.createElement("a");
  auditLink.href = `/ui/repos/${encoded}/audit`;
  auditLink.className = "repository-more-item";
  if (auditRoute) auditLink.setAttribute("aria-current", "page");
  auditLink.append(interfaceIcon("audit"), document.createTextNode("Audit"));
  moreMenu.append(auditLink);
  more.append(moreSummary, moreMenu);
  tabList.append(more);
  inner.append(identityRow, tabList);
  repositoryNavigation.append(inner);
  void loadRepositoryTabCounts(repository, countTargets);
}

async function copyText(value, control) {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(value);
    } else {
      const input = control.closest(".clone-field")?.querySelector("input");
      input?.select();
      document.execCommand("copy");
    }
    const previous = control.getAttribute("aria-label");
    control.setAttribute("aria-label", "Copied");
    control.classList.add("is-copied");
    window.setTimeout(() => {
      control.setAttribute("aria-label", previous || "Copy clone URL");
      control.classList.remove("is-copied");
    }, 1600);
  } catch (_error) {
    control.setAttribute("aria-label", "Copy failed");
  }
}

function referenceHref(encoded, name) {
  return `/ui/repos/${encoded}/files/${encodeURIComponent(shortReference(name))}`;
}

function createReferenceSwitcher(options) {
  const {encoded, branches, tags, current, defaultBranch} = options;
  const menu = document.createElement("details");
  menu.className = "ref-switcher";
  const summary = document.createElement("summary");
  summary.className = "button button-secondary ref-switcher-summary";
  summary.id = "reference-switcher";
  const summaryName = document.createElement("span");
  summaryName.className = "ref-switcher-name";
  summaryName.textContent = current ? shortReference(current.name) : "No branches yet";
  summary.append(interfaceIcon("branch"), summaryName);

  const popover = document.createElement("div");
  popover.className = "ref-switcher-popover";
  const header = document.createElement("div");
  header.className = "ref-switcher-header";
  const heading = document.createElement("strong");
  heading.textContent = "Switch branches/tags";
  const close = document.createElement("button");
  close.className = "icon-button ref-switcher-close";
  close.type = "button";
  close.setAttribute("aria-label", "Close the branch and tag menu");
  close.append(interfaceIcon("close"));
  close.addEventListener("click", () => {
    menu.open = false;
    summary.focus();
  });
  header.append(heading, close);

  const search = document.createElement("div");
  search.className = "ref-search";
  const filterLabel = document.createElement("label");
  filterLabel.className = "sr-only";
  filterLabel.htmlFor = "reference-filter";
  filterLabel.textContent = "Find or create a branch";
  const filter = document.createElement("input");
  filter.id = "reference-filter";
  filter.type = "text";
  filter.autocomplete = "off";
  filter.placeholder = "Find or create a branch...";
  search.append(filterLabel, interfaceIcon("search", "ref-search-icon"), filter);

  const tabs = document.createElement("div");
  tabs.className = "ref-tabs";
  tabs.setAttribute("role", "tablist");
  tabs.setAttribute("aria-label", "Reference kind");
  const panels = {};
  const lists = {};
  const tabButtons = {};
  for (const kind of ["branches", "tags"]) {
    const tab = document.createElement("button");
    tab.className = "ref-tab";
    tab.type = "button";
    tab.id = `ref-tab-${kind}`;
    tab.setAttribute("role", "tab");
    tab.setAttribute("aria-controls", `ref-panel-${kind}`);
    tab.textContent = kind === "branches" ? "Branches" : "Tags";
    tabs.append(tab);
    tabButtons[kind] = tab;
    const panel = document.createElement("div");
    panel.className = "ref-panel";
    panel.id = `ref-panel-${kind}`;
    panel.setAttribute("role", "tabpanel");
    panel.setAttribute("aria-labelledby", tab.id);
    const list = document.createElement("ul");
    list.className = "ref-list";
    panel.append(list);
    panels[kind] = panel;
    lists[kind] = list;
  }

  const empty = document.createElement("p");
  empty.className = "muted-message ref-empty";
  const create = document.createElement("button");
  create.className = "ref-create";
  create.type = "button";
  create.hidden = true;
  const createText = document.createElement("span");
  create.append(interfaceIcon("plus"), createText);
  const status = document.createElement("p");
  status.className = "form-status ref-status";
  status.setAttribute("role", "status");
  popover.append(header, search, tabs, panels.branches, panels.tags, empty, create, status);
  menu.append(summary, popover);

  const rows = {branches: [], tags: []};
  for (const [kind, references] of [["branches", branches], ["tags", tags]]) {
    for (const reference of references) {
      const short = shortReference(reference.name);
      const item = document.createElement("li");
      const link = document.createElement("a");
      link.className = "ref-item";
      link.href = referenceHref(encoded, reference.name);
      if (reference.name === current?.name) link.setAttribute("aria-current", "true");
      const mark = document.createElement("span");
      mark.className = "ref-item-mark";
      if (reference.name === current?.name) mark.append(interfaceIcon("check"));
      const name = document.createElement("span");
      name.className = "ref-item-name";
      name.textContent = short;
      link.append(mark, name);
      if (kind === "branches" && short === defaultBranch) {
        const badge = document.createElement("span");
        badge.className = "ref-item-badge";
        badge.textContent = "default";
        link.append(badge);
      }
      item.append(link);
      lists[kind].append(item);
      rows[kind].push({short, item, link});
    }
  }

  let active = "branches";
  const render = () => {
    const query = filter.value.trim();
    const lowered = query.toLocaleLowerCase();
    let visible = 0;
    for (const kind of ["branches", "tags"]) {
      panels[kind].hidden = kind !== active;
      for (const row of rows[kind]) {
        const matches = !lowered || row.short.toLocaleLowerCase().includes(lowered);
        row.item.hidden = !matches;
        if (matches && kind === active) visible += 1;
      }
    }
    const exists = rows.branches.some((row) => row.short === query);
    const offerCreate = active === "branches" && Boolean(query) && !exists
      && Boolean(current?.oid);
    create.hidden = !offerCreate;
    createText.replaceChildren(
      document.createTextNode("Create branch "),
      Object.assign(document.createElement("strong"), {textContent: query}),
      document.createTextNode(` from ${shortReference(current?.name)}`),
    );
    empty.hidden = visible > 0 || offerCreate;
    empty.textContent = active === "branches"
      ? "No matching branches." : "No matching tags.";
  };
  const selectTab = (kind) => {
    active = kind;
    for (const [name, tab] of Object.entries(tabButtons)) {
      tab.classList.toggle("is-active", name === kind);
      tab.setAttribute("aria-selected", String(name === kind));
    }
    filter.placeholder = kind === "branches"
      ? "Find or create a branch..." : "Find a tag...";
    filterLabel.textContent = kind === "branches"
      ? "Find or create a branch" : "Find a tag";
    render();
  };
  for (const [kind, tab] of Object.entries(tabButtons)) {
    tab.addEventListener("click", () => {
      selectTab(kind);
      filter.focus();
    });
  }
  filter.addEventListener("input", render);

  const visibleTargets = () => {
    const links = rows[active].filter((row) => !row.item.hidden).map((row) => row.link);
    return create.hidden ? links : [...links, create];
  };
  filter.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      visibleTargets()[0]?.focus();
    } else if (event.key === "Enter") {
      event.preventDefault();
      visibleTargets()[0]?.click();
    }
  });
  popover.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      menu.open = false;
      summary.focus();
      return;
    }
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return;
    const targets = visibleTargets();
    const index = targets.indexOf(document.activeElement);
    if (index < 0) return;
    event.preventDefault();
    const next = event.key === "ArrowDown" ? index + 1 : index - 1;
    if (next < 0) filter.focus();
    else targets[next]?.focus();
  });
  let requested = null;
  menu.addEventListener("toggle", () => {
    if (!menu.open) return;
    filter.value = "";
    status.textContent = "";
    status.className = "form-status ref-status";
    selectTab(requested || "branches");
    requested = null;
    filter.focus();
  });
  document.addEventListener("click", (event) => {
    if (menu.open && !menu.contains(event.target)) menu.open = false;
  });
  const openAt = (kind) => {
    if (menu.open) {
      selectTab(kind);
      filter.focus();
      return;
    }
    requested = kind;
    menu.open = true;
  };

  create.addEventListener("click", async () => {
    const name = filter.value.trim();
    create.disabled = true;
    status.className = "form-status ref-status";
    status.textContent = `Creating ${name}...`;
    try {
      const response = await fetch(`/api/repos/${encoded}/branches`, {
        method: "POST",
        headers: {"content-type": "application/json"},
        body: JSON.stringify({name, oid: current.oid}),
      });
      if (!response.ok) {
        const problem = await response.json().catch(() => null);
        throw new Error(problem?.detail || `branch create returned ${response.status}`);
      }
      const created = await response.json();
      window.location.href = referenceHref(encoded, created.name);
    } catch (error) {
      create.disabled = false;
      status.className = "form-status is-error ref-status";
      status.textContent = error.message || "The branch could not be created.";
    }
  });

  selectTab("branches");
  return {menu, openAt};
}

function createCodeMenu(cloneUrl) {
  const menu = document.createElement("details");
  menu.className = "code-menu";
  const summary = document.createElement("summary");
  summary.className = "button code-menu-summary";
  summary.append(interfaceIcon("code"), document.createTextNode("Code"));
  const popover = document.createElement("div");
  popover.className = "code-menu-popover";
  const heading = document.createElement("strong");
  heading.textContent = "Clone with HTTPS";
  const cloneField = document.createElement("div");
  cloneField.className = "clone-field";
  const clone = document.createElement("input");
  clone.readOnly = true;
  clone.value = cloneUrl;
  clone.setAttribute("aria-label", "HTTPS clone URL");
  const copy = document.createElement("button");
  copy.className = "icon-button clone-copy";
  copy.type = "button";
  copy.setAttribute("aria-label", "Copy clone URL");
  copy.append(interfaceIcon("copy"));
  copy.addEventListener("click", () => copyText(cloneUrl, copy));
  cloneField.append(clone, copy);
  const hint = document.createElement("p");
  hint.textContent = "Use Git to clone this repository over HTTPS.";
  popover.append(heading, cloneField, hint);
  menu.append(summary, popover);
  return menu;
}

if (window.location.pathname !== "/") {
  createRepositoryLink.hidden = true;
  pageLede.hidden = false;
  panel.removeAttribute("aria-label");
  panel.classList.add("page-content-panel");
  dashboard.className = "page-dashboard";
}
if (repositoryPageRoute) {
  const repositoryName = decodeURIComponent(repositoryPageRoute[1]);
  pageIntro.classList.add("repository-page-intro");
  showRepositoryNavigation(repositoryName);
}
if (window.location.pathname === "/ui/create") showCreateForm();
else if (pullRequestListRoute) showPullRequests(decodeURIComponent(pullRequestListRoute[1]));
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
  name.autofocus = true;
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
  name.focus();
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
      window.location.href = `/ui/repos/${encodeURIComponent(body.name)}`;
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
    const [repositoryResponse, branchesResponse, tagsResponse] = await Promise.all([
      fetch(`/api/repos/${encoded}`),
      fetch(`/api/repos/${encoded}/branches`),
      fetch(`/api/repos/${encoded}/tags`),
    ]);
    if (!repositoryResponse.ok) throw new Error("repository not found");
    const repository = await repositoryResponse.json();
    const branches = branchesResponse.ok ? await branchesResponse.json() : [];
    const tags = tagsResponse.ok ? await tagsResponse.json() : [];
    const defaultBranchName = String(repository.default_branch || "")
      .replace(/^refs\/heads\//, "");
    const defaultReference = branches.find((reference) => reference.name === repository.default_branch
      || reference.name === `refs/heads/${defaultBranchName}`)?.name
      || branches[0]?.name || "";
    const contentsResponse = defaultReference ? await fetch(
      `/api/repos/${encoded}/contents/?ref=${encodeURIComponent(defaultReference)}`,
      {headers: {accept: "application/json"}},
    ) : null;
    const contents = contentsResponse?.ok ? await contentsResponse.json() : null;
    dashboard.replaceChildren();
    const cloneUrl = `${window.location.origin}/${repository.name}.git`;
    const selector = document.createElement("div");
    selector.className = "reference-toolbar";
    const branchControl = document.createElement("div");
    branchControl.className = "branch-control";
    const switcher = createReferenceSwitcher({
      encoded,
      branches,
      tags,
      current: branches.find((reference) => reference.name === defaultReference),
      defaultBranch: defaultBranchName,
    });
    branchControl.append(switcher.menu);
    const revealReferences = (event, kind) => {
      event.stopPropagation();
      switcher.openAt(kind);
    };
    const branchCount = document.createElement("button");
    branchCount.className = "reference-count";
    branchCount.type = "button";
    branchCount.append(
      interfaceIcon("branch"),
      document.createTextNode(
        `${branches.length} ${branches.length === 1 ? "Branch" : "Branches"}`,
      ),
    );
    branchCount.addEventListener("click", (event) => revealReferences(event, "branches"));
    const tagCount = document.createElement("button");
    tagCount.className = "reference-count";
    tagCount.type = "button";
    tagCount.append(
      interfaceIcon("tag"),
      document.createTextNode(`${tags.length} ${tags.length === 1 ? "Tag" : "Tags"}`),
    );
    tagCount.addEventListener("click", (event) => revealReferences(event, "tags"));
    const contentsPanel = document.createElement("section");
    contentsPanel.className = "repository-contents";
    const latestEntry = Array.isArray(contents?.entries)
      ? contents.entries.find((entry) => entry.last_commit || entry.last_commit_at)
      : null;
    const commitLine = document.createElement("div");
    commitLine.className = "contents-commit";
    const commitAvatar = document.createElement("span");
    commitAvatar.className = "commit-avatar";
    commitAvatar.setAttribute("aria-hidden", "true");
    commitAvatar.textContent = "H";
    const commitSummary = document.createElement("div");
    commitSummary.className = "contents-commit-summary";
    const commitLabel = document.createElement("strong");
    commitLabel.className = "contents-commit-label";
    commitLabel.textContent = "Latest commit";
    const commitDescription = document.createElement("span");
    commitDescription.className = "contents-commit-description";
    commitDescription.textContent = latestEntry?.last_commit || "No commit description available.";
    commitSummary.append(commitLabel, commitDescription);
    const commitMeta = document.createElement("div");
    commitMeta.className = "contents-commit-meta";
    if (latestEntry?.last_commit_at !== undefined) {
      const commitDate = commitTimestampDate(latestEntry.last_commit_at);
      const commitTime = document.createElement("time");
      commitTime.className = "contents-commit-time";
      if (commitDate) commitTime.dateTime = commitDate.toISOString();
      commitTime.textContent = formatCommitTimestamp(latestEntry.last_commit_at);
      commitMeta.append(commitTime);
    }
    if (defaultReference) {
      const history = document.createElement("a");
      history.className = "commit-history-link";
      history.href = `/ui/repos/${encoded}/commits/${encodeURIComponent(defaultBranchName)}`;
      history.textContent = "History";
      commitMeta.append(history);
    }
    commitLine.append(commitAvatar, commitSummary, commitMeta);
    const contentsList = document.createElement("ul");
    contentsList.className = "tree-list";
    if (!Array.isArray(contents?.entries) || !contents.entries.length) {
      const empty = document.createElement("li");
      empty.className = "muted-message";
      empty.textContent = defaultReference ? "This directory is empty." : "No branch is available.";
      contentsList.append(empty);
    } else {
      const contentBranch = defaultReference.replace(/^refs\/heads\//, "");
      contents.entries.forEach((entry) => contentsList.append(
        renderTreeEntry(entry, name, contentBranch, ""),
      ));
    }
    const referenceGroup = document.createElement("div");
    referenceGroup.className = "reference-group";
    referenceGroup.append(branchControl, branchCount, tagCount);
    const toolbarActions = document.createElement("div");
    toolbarActions.className = "code-toolbar-actions";
    toolbarActions.append(createCodeMenu(cloneUrl));
    selector.append(referenceGroup, toolbarActions);
    contentsPanel.append(commitLine, contentsList);
    const readme = document.createElement("section");
    readme.className = "readme-panel";
    const readmeTitle = document.createElement("h2");
    readmeTitle.textContent = "README";
    const readmeContent = document.createElement("div");
    readmeContent.className = "readme-content";
    readmeContent.append(...renderMarkdownSafe(repository.readme).childNodes);
    if (!readmeContent.childNodes.length) {
      readmeContent.className = "readme-content muted-message";
      readmeContent.textContent = "No README is available for this repository.";
    }
    readme.append(readmeTitle, readmeContent);
    dashboard.append(selector, contentsPanel, readme);
  } catch (_error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "This repository could not be loaded.";
    dashboard.append(failure);
  }
}

function reviewStateLabel(state) {
  return {
    approved: "Approved",
    request_changes: "Requested changes",
    commented: "Commented",
  }[state] || "Reviewed";
}

function pullDiscussion(reviews, comments) {
  const entries = [
    ...comments.map((comment) => ({...comment, kind: "comment"})),
    ...reviews.map((review) => ({...review, kind: "review"})),
  ];
  entries.sort((left, right) => String(left.created_at || "")
    .localeCompare(String(right.created_at || "")));
  return entries.map((entry) => {
    const card = document.createElement("article");
    card.className = entry.kind === "review"
      ? "timeline-card pull-review" : "timeline-card pull-comment";
    const header = document.createElement("header");
    header.append(createAvatar(entry.actor));
    const meta = document.createElement("p");
    const who = document.createElement("strong");
    who.textContent = entry.actor || "unknown";
    const action = entry.kind === "review"
      ? `${reviewStateLabel(entry.state).toLocaleLowerCase()} these changes`
      : "commented";
    meta.append(who, document.createTextNode(
      ` ${action} ${formatRelativeTimestamp(entry.created_at)}`,
    ));
    header.append(meta);
    if (entry.kind === "review") {
      const badge = document.createElement("span");
      badge.className = `review-state is-${entry.state}`;
      badge.textContent = reviewStateLabel(entry.state);
      header.append(badge);
    }
    card.append(header);
    if (entry.body) {
      const text = document.createElement("div");
      text.className = "timeline-body";
      const paragraph = document.createElement("p");
      paragraph.textContent = entry.body;
      text.append(paragraph);
      card.append(text);
    }
    return card;
  });
}

function createPullComposer(context) {
  const {repository, id, encodedRepository, encodedId} = context;
  const composer = document.createElement("form");
  composer.className = "comment-composer pull-composer";
  const card = document.createElement("div");
  card.className = "comment-composer-card";
  const bodyLabel = document.createElement("label");
  bodyLabel.htmlFor = "pull-comment-body";
  bodyLabel.textContent = "Add a comment";
  const body = document.createElement("textarea");
  body.id = "pull-comment-body";
  body.rows = 5;
  body.placeholder = "Leave a comment";
  const reviewLabel = document.createElement("label");
  reviewLabel.htmlFor = "pull-review-state";
  reviewLabel.textContent = "Review verdict";
  const reviewState = document.createElement("select");
  reviewState.id = "pull-review-state";
  for (const [value, text] of [
    ["comment", "Comment only"],
    ["approved", "Approve"],
    ["request_changes", "Request changes"],
  ]) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = text;
    reviewState.append(option);
  }
  const footer = document.createElement("div");
  footer.className = "composer-footer";
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  const group = document.createElement("div");
  group.className = "form-actions";
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Submit";
  group.append(submit);
  footer.append(status, group);
  card.append(bodyLabel, body, reviewLabel, reviewState, footer);
  composer.append(createAvatar("H"), card);
  composer.addEventListener("submit", async (event) => {
    event.preventDefault();
    const text = body.value.trim();
    const verdict = reviewState.value;
    if (!text && verdict === "comment") {
      status.className = "form-status is-error";
      status.textContent = "Write a comment or choose a review verdict.";
      return;
    }
    submit.disabled = true;
    const resource = verdict === "comment" ? "comments" : "reviews";
    const payload = verdict === "comment"
      ? {id: generateInternalId(), body: text}
      : {id: generateInternalId(), state: verdict, body: text};
    try {
      const posted = await fetch(
        `/api/repos/${encodedRepository}/pulls/${encodedId}/${resource}`,
        {
          method: "POST",
          headers: {"content-type": "application/json"},
          body: JSON.stringify(payload),
        },
      );
      if (!posted.ok) throw new Error("submit failed");
      await showPullRequest(repository, id);
    } catch (_error) {
      submit.disabled = false;
      status.className = "form-status is-error";
      status.textContent = "The review could not be submitted.";
    }
  });
  return composer;
}

async function showPullRequest(repository, id) {
  dashboard.replaceChildren();
  const loading = document.createElement("p");
  loading.className = "muted-message";
  loading.textContent = "Loading pull request...";
  dashboard.append(loading);
  try {
    const encodedRepository = encodeURIComponent(repository);
    const encodedId = encodeURIComponent(id);
    const [response, reviewsResponse, commentsResponse] = await Promise.all([
      fetch(`/api/repos/${encodedRepository}/pulls/${encodedId}`, {
        headers: {accept: "application/json"},
      }),
      fetch(`/api/repos/${encodedRepository}/pulls/${encodedId}/reviews`),
      fetch(`/api/repos/${encodedRepository}/pulls/${encodedId}/comments`),
    ]);
    if (!response.ok) throw new Error(`pull request returned ${response.status}`);
    const pullRequest = await response.json();
    const reviews = reviewsResponse.ok ? await reviewsResponse.json() : [];
    const comments = commentsResponse.ok ? await commentsResponse.json() : [];
    const source = shortReference(pullRequest.source_ref);
    const target = shortReference(pullRequest.target_ref);
    pageTitle.textContent = "Pull request";
    pageLede.textContent = `#${pullRequest.id} · ${repository}`;
    dashboard.replaceChildren();

    const summary = document.createElement("div");
    summary.className = "work-detail-summary";
    const titleLine = document.createElement("div");
    titleLine.className = "detail-title-line";
    const visibleTitle = document.createElement("h1");
    visibleTitle.textContent = `${source} into ${target}`;
    const number = document.createElement("span");
    number.textContent = `#${pullRequest.id}`;
    titleLine.append(visibleTitle, number);
    const stateLine = document.createElement("div");
    stateLine.className = "work-detail-state-line";
    stateLine.append(createStateBadge(pullRequest.state, "pull"));
    const summaryText = document.createElement("p");
    summaryText.append(document.createTextNode(" wants to merge "));
    const commitsLink = document.createElement("a");
    commitsLink.href = `/ui/repos/${encodedRepository}/commits/${encodeURIComponent(source)}`;
    commitsLink.textContent = source;
    const targetCode = document.createElement("code");
    targetCode.textContent = target;
    summaryText.append(commitsLink, document.createTextNode(" into "), targetCode);
    stateLine.append(summaryText);
    summary.append(titleLine, stateLine);

    const tabs = document.createElement("nav");
    tabs.className = "detail-tabs";
    tabs.setAttribute("aria-label", "Pull request sections");
    const conversationTab = document.createElement("button");
    conversationTab.type = "button";
    conversationTab.className = "detail-tab is-active";
    conversationTab.textContent = "Conversation";
    conversationTab.setAttribute("aria-selected", "true");
    const commitsTab = document.createElement("a");
    commitsTab.className = "detail-tab";
    commitsTab.href = `/ui/repos/${encodedRepository}/commits/${encodeURIComponent(source)}`;
    commitsTab.textContent = "Commits";
    const checksTab = document.createElement("button");
    checksTab.type = "button";
    checksTab.className = "detail-tab";
    checksTab.textContent = "Checks";
    checksTab.disabled = true;
    checksTab.title = "Checks are not configured for this repository";
    const filesTab = document.createElement("button");
    filesTab.type = "button";
    filesTab.className = "detail-tab";
    filesTab.textContent = "Files changed";
    filesTab.setAttribute("aria-selected", "false");
    tabs.append(conversationTab, commitsTab, checksTab, filesTab);

    const conversation = document.createElement("div");
    conversation.className = "detail-panel";
    const layout = document.createElement("div");
    layout.className = "discussion-layout";
    const main = document.createElement("div");
    main.className = "discussion-main";
    const timeline = document.createElement("article");
    timeline.className = "timeline-card";
    const timelineHeader = document.createElement("header");
    timelineHeader.append(createAvatar("H"));
    const timelineMeta = document.createElement("p");
    timelineMeta.append(document.createTextNode("This pull request compares "));
    const sourceCode = document.createElement("code");
    sourceCode.textContent = source;
    const baseCode = document.createElement("code");
    baseCode.textContent = target;
    timelineMeta.append(sourceCode, document.createTextNode(" with "), baseCode, document.createTextNode("."));
    timelineHeader.append(timelineMeta);
    const timelineBody = document.createElement("div");
    timelineBody.className = "timeline-body";
    const timelineText = document.createElement("p");
    timelineText.textContent = "Review the changed files and merge when the branch is ready.";
    timelineBody.append(timelineText);
    timeline.append(timelineHeader, timelineBody);

    const mergeability = pullRequest.mergeability || "unknown";
    const mergeExplanation = {
      clean: "This branch has no conflicts with the base branch.",
      conflicting: "Resolve the conflicting files before merging.",
      stale: "The source or target branch moved. Refresh the comparison.",
      blocked: "Branch protection or required reviews are blocking the merge.",
      unknown: "Mergeability has not been calculated yet.",
    }[mergeability] || "Mergeability could not be determined.";
    const mergeBox = document.createElement("section");
    mergeBox.className = `merge-box is-${mergeability}`;
    const mergeHeading = document.createElement("h2");
    mergeHeading.textContent = mergeability === "clean"
      ? "This branch has no conflicts with the base branch"
      : `Merge status: ${mergeability}`;
    const mergeMessage = document.createElement("p");
    mergeMessage.textContent = mergeExplanation;
    const actions = document.createElement("div");
    actions.className = "pull-request-actions";
    const nextState = {draft: "open", open: "closed", closed: "open"}[pullRequest.state];
    if (nextState) {
      const stateAction = document.createElement("button");
      stateAction.className = "button button-secondary";
      stateAction.type = "button";
      stateAction.textContent = pullRequest.state === "draft"
        ? "Ready for review" : nextState === "closed" ? "Close pull request" : "Reopen pull request";
      stateAction.addEventListener("click", async () => {
        stateAction.disabled = true;
        try {
          const update = await fetch(`/api/repos/${encodedRepository}/pulls/${encodedId}`, {
            method: "PATCH",
            headers: {"content-type": "application/json", "if-match": `"${pullRequest.version}"`},
            body: JSON.stringify({state: nextState}),
          });
          if (!update.ok) throw new Error("update failed");
          await showPullRequest(repository, id);
        } catch (_error) {
          stateAction.disabled = false;
          stateAction.textContent = "Update failed; try again";
        }
      });
      actions.append(stateAction);
    }
    if (pullRequest.state === "open") {
      const mergeAction = document.createElement("button");
      mergeAction.className = "button";
      mergeAction.type = "button";
      mergeAction.textContent = "Merge pull request";
      mergeAction.disabled = mergeability === "conflicting" || mergeability === "blocked";
      mergeAction.addEventListener("click", async () => {
        mergeAction.disabled = true;
        try {
          const merge = await fetch(`/api/repos/${encodedRepository}/pulls/${encodedId}/merge`, {
            method: "PUT",
            headers: {"content-type": "application/json"},
            body: JSON.stringify({expected_head_oid: pullRequest.head_oid, clean: true}),
          });
          if (!merge.ok) throw new Error("merge failed");
          await showPullRequest(repository, id);
        } catch (_error) {
          mergeAction.disabled = false;
          mergeAction.textContent = "Merge failed; try again";
        }
      });
      actions.prepend(mergeAction);
    }
    mergeBox.append(mergeHeading, mergeMessage, actions);
    main.append(timeline);

    for (const entry of pullDiscussion(reviews, comments)) {
      main.append(entry);
    }
    main.append(mergeBox, createPullComposer({
      repository,
      id,
      encodedRepository,
      encodedId,
    }));

    const sidebar = createMetadataSidebar([
      ["Reviewers", createMetadataList(
        reviews.map((review) => ({
          primary: review.actor || "unknown",
          secondary: reviewStateLabel(review.state),
        })),
        "No reviews yet",
      )],
      ["Development", `${source} into ${target}`],
    ]);
    const technical = document.createElement("details");
    technical.className = "technical-details";
    const technicalSummary = document.createElement("summary");
    technicalSummary.textContent = "Technical details";
    const details = document.createElement("dl");
    details.className = "repository-meta";
    for (const [label, value] of [["Base", pullRequest.base_oid], ["Head", pullRequest.head_oid], ["Version", pullRequest.version]]) {
      const term = document.createElement("dt");
      term.textContent = label;
      const detail = document.createElement("dd");
      detail.textContent = String(value);
      details.append(term, detail);
    }
    technical.append(technicalSummary, details);
    sidebar.append(technical);
    layout.append(main, sidebar);
    conversation.append(layout);

    const files = document.createElement("div");
    files.className = "detail-panel";
    files.hidden = true;
    const filesLoading = document.createElement("p");
    filesLoading.className = "muted-message";
    filesLoading.textContent = "Loading changed files...";
    files.append(filesLoading);
    const selectPanel = (selected) => {
      const showingFiles = selected === "files";
      conversation.hidden = showingFiles;
      files.hidden = !showingFiles;
      conversationTab.classList.toggle("is-active", !showingFiles);
      filesTab.classList.toggle("is-active", showingFiles);
      conversationTab.setAttribute("aria-selected", String(!showingFiles));
      filesTab.setAttribute("aria-selected", String(showingFiles));
    };
    conversationTab.addEventListener("click", () => selectPanel("conversation"));
    filesTab.addEventListener("click", () => selectPanel("files"));
    dashboard.append(summary, tabs, conversation, files);
    try {
      const params = new URLSearchParams({base: pullRequest.target_ref, head: pullRequest.source_ref});
      const compare = await fetch(`/api/repos/${encodedRepository}/compare?${params}`);
      if (!compare.ok) throw new Error("comparison unavailable");
      files.replaceChildren(renderUnifiedDiffSafe(await compare.json()));
    } catch (_error) {
      filesLoading.textContent = "Changed files are not available for this pull request.";
    }
  } catch (_error) {
    dashboard.replaceChildren();
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "This pull request could not be loaded.";
    dashboard.append(failure);
  }
}

async function showPullRequests(repository) {
  pageTitle.textContent = "Pull requests";
  pageLede.textContent = `${repository} · propose and review changes.`;
  dashboard.replaceChildren();
  try {
    const encoded = encodeURIComponent(repository);
    const response = await fetch(`/api/repos/${encoded}/pulls`, {headers: {accept: "application/json"}});
    if (!response.ok) throw new Error(`pull requests returned ${response.status}`);
    const pullRequests = await response.json();
    dashboard.append(createWorkList({
      items: pullRequests,
      kind: "pull",
      createHref: `/ui/repos/${encoded}/pulls/new`,
      renderRow: (pullRequest) => {
        const row = document.createElement("article");
        row.className = "work-row";
        const icon = document.createElement("span");
        icon.className = `work-row-icon is-${pullRequest.state}`;
        icon.append(interfaceIcon("pull"));
        const content = document.createElement("div");
        content.className = "work-row-content";
        const heading = document.createElement("h2");
        const link = document.createElement("a");
        link.href = `/ui/repos/${encoded}/pulls/${encodeURIComponent(pullRequest.id)}`;
        link.textContent = `${shortReference(pullRequest.source_ref)} into ${shortReference(pullRequest.target_ref)}`;
        heading.append(link);
        const meta = document.createElement("p");
        meta.textContent = `#${pullRequest.id} · ${pullRequest.state === "draft" ? "Draft" : pullRequest.state} · ${shortReference(pullRequest.source_ref)} → ${shortReference(pullRequest.target_ref)}`;
        content.append(heading, meta);
        row.append(icon, content);
        return row;
      },
    }));
  } catch (_error) {
    const failure = document.createElement("p");
    failure.className = "muted-message";
    failure.textContent = "Pull requests could not be loaded.";
    dashboard.append(failure);
  }
}

async function showIssues(repository) {
  pageTitle.textContent = "Issues";
  pageLede.textContent = `${repository} · track work and discussions.`;
  dashboard.replaceChildren();
  try {
    const encoded = encodeURIComponent(repository);
    const response = await fetch(`/api/repos/${encoded}/issues`, {headers: {accept: "application/json"}});
    if (!response.ok) throw new Error(`issues returned ${response.status}`);
    const issues = await response.json();
    dashboard.append(createWorkList({
      items: issues,
      kind: "issue",
      createHref: `/ui/repos/${encoded}/issues/new`,
      renderRow: (issue) => {
        const row = document.createElement("article");
        row.className = "work-row";
        const icon = document.createElement("span");
        icon.className = `work-row-icon is-${issue.state}`;
        icon.append(interfaceIcon("issue"));
        const content = document.createElement("div");
        content.className = "work-row-content";
        const heading = document.createElement("h2");
        const link = document.createElement("a");
        link.href = `/ui/repos/${encoded}/issues/${encodeURIComponent(issue.id)}`;
        link.textContent = issue.title;
        heading.append(link);
        const meta = document.createElement("p");
        const actor = issue.actor || "unknown";
        meta.textContent = `#${issue.id} opened ${formatRelativeTimestamp(issue.created_at)} by ${actor}`;
        content.append(heading, meta);
        row.append(icon, content);
        return row;
      },
    }));
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
  pageTitle.textContent = "Open a new issue";
  pageLede.textContent = `${repository} · describe a task, bug, or discussion.`;
  dashboard.replaceChildren();
  const layout = document.createElement("div");
  layout.className = "create-work-layout";
  const form = document.createElement("form");
  form.className = "repository-form issue-form create-work-form";
  const heading = document.createElement("h2");
  heading.textContent = "Add a title and description";
  const titleLabel = document.createElement("label");
  titleLabel.htmlFor = "issue-title";
  titleLabel.textContent = "Title";
  const title = document.createElement("input");
  title.id = "issue-title";
  title.name = "title";
  title.required = true;
  title.maxLength = 255;
  title.placeholder = "Title";
  const bodyLabel = document.createElement("label");
  bodyLabel.htmlFor = "issue-body";
  bodyLabel.textContent = "Description";
  const body = document.createElement("textarea");
  body.id = "issue-body";
  body.name = "body";
  body.rows = 10;
  body.maxLength = 10000;
  body.placeholder = "Add a description, steps to reproduce, or other context. Markdown is supported.";
  const footer = document.createElement("div");
  footer.className = "form-actions";
  const cancel = document.createElement("a");
  cancel.className = "button button-secondary";
  cancel.href = `/ui/repos/${encodeURIComponent(repository)}/issues`;
  cancel.textContent = "Cancel";
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Create issue";
  footer.append(cancel, submit);
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  form.append(heading, titleLabel, title, bodyLabel, body, footer, status);
  layout.append(createAvatar("H"), form);
  dashboard.append(layout);
  title.focus();
  const submissionKey = generateInternalId();
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    submit.disabled = true;
    status.textContent = "Creating issue...";
    try {
      const response = await fetch(`/api/repos/${encodeURIComponent(repository)}/issues`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": submissionKey,
        },
        body: JSON.stringify({title: title.value, body: body.value}),
      });
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
  dashboard.replaceChildren();
  const loading = document.createElement("p");
  loading.className = "muted-message";
  loading.textContent = "Loading issue...";
  dashboard.append(loading);
  try {
    const encodedRepository = encodeURIComponent(repository);
    const encodedId = encodeURIComponent(id);
    const [issueResponse, commentsResponse, labelsResponse, assigneesResponse] = await Promise.all([
      fetch(`/api/repos/${encodedRepository}/issues/${encodedId}`),
      fetch(`/api/repos/${encodedRepository}/issues/${encodedId}/comments`),
      fetch(`/api/repos/${encodedRepository}/issues/${encodedId}/labels`),
      fetch(`/api/repos/${encodedRepository}/issues/${encodedId}/assignees`),
    ]);
    if (!issueResponse.ok) throw new Error("issue not found");
    const issue = await issueResponse.json();
    const comments = commentsResponse.ok ? await commentsResponse.json() : [];
    const labels = labelsResponse.ok
      ? (await labelsResponse.json()).map((entry) => entry.label) : [];
    const assignees = assigneesResponse.ok
      ? (await assigneesResponse.json()).map((entry) => entry.actor) : [];
    const actor = issue.actor || "unknown";
    pageTitle.textContent = "Issue";
    pageLede.textContent = `#${issue.id} · ${repository}`;
    dashboard.replaceChildren();

    const summary = document.createElement("div");
    summary.className = "work-detail-summary";
    const titleLine = document.createElement("div");
    titleLine.className = "detail-title-line";
    const visibleTitle = document.createElement("h1");
    visibleTitle.textContent = issue.title;
    const number = document.createElement("span");
    number.textContent = `#${issue.id}`;
    titleLine.append(visibleTitle, number);
    const stateLine = document.createElement("div");
    stateLine.className = "work-detail-state-line";
    stateLine.append(createStateBadge(issue.state));
    const summaryText = document.createElement("p");
    summaryText.textContent = `${actor} opened this issue ${formatRelativeTimestamp(issue.created_at)} · ${comments.length} ${comments.length === 1 ? "comment" : "comments"}`;
    stateLine.append(summaryText);
    summary.append(titleLine, stateLine);

    const layout = document.createElement("div");
    layout.className = "discussion-layout";
    const main = document.createElement("div");
    main.className = "discussion-main";
    const description = document.createElement("article");
    description.className = "timeline-card";
    const descriptionHeader = document.createElement("header");
    descriptionHeader.append(createAvatar(actor));
    const descriptionMeta = document.createElement("p");
    const author = document.createElement("strong");
    author.textContent = actor;
    descriptionMeta.append(author, document.createTextNode(` commented ${formatRelativeTimestamp(issue.created_at)}`));
    const editToggle = document.createElement("button");
    editToggle.className = "icon-button timeline-edit";
    editToggle.type = "button";
    editToggle.textContent = "Edit";
    editToggle.setAttribute("aria-expanded", "false");
    descriptionHeader.append(descriptionMeta, editToggle);
    const renderedBody = document.createElement("div");
    renderedBody.className = "timeline-body readme-content";
    if (issue.body) renderedBody.append(...renderMarkdownSafe(issue.body).childNodes);
    else {
      const empty = document.createElement("p");
      empty.className = "muted-message";
      empty.textContent = "No description provided.";
      renderedBody.append(empty);
    }
    const edit = document.createElement("form");
    edit.className = "repository-form issue-edit-form";
    edit.hidden = true;
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
    bodyInput.rows = 8;
    bodyInput.value = issue.body || "";
    const editActions = document.createElement("div");
    editActions.className = "form-actions";
    const cancelEdit = document.createElement("button");
    cancelEdit.className = "button button-secondary";
    cancelEdit.type = "button";
    cancelEdit.textContent = "Cancel";
    const editButton = document.createElement("button");
    editButton.className = "button";
    editButton.type = "submit";
    editButton.textContent = "Save changes";
    editActions.append(cancelEdit, editButton);
    const editStatus = document.createElement("p");
    editStatus.className = "form-status";
    editStatus.setAttribute("role", "status");
    edit.append(titleLabel, titleInput, bodyLabel, bodyInput, editActions, editStatus);
    const toggleEdit = (open) => {
      edit.hidden = !open;
      renderedBody.hidden = open;
      editToggle.setAttribute("aria-expanded", String(open));
      if (open) titleInput.focus();
    };
    editToggle.addEventListener("click", () => toggleEdit(edit.hidden));
    cancelEdit.addEventListener("click", () => toggleEdit(false));
    edit.addEventListener("submit", async (event) => {
      event.preventDefault();
      editButton.disabled = true;
      try {
        const response = await fetch(`/api/repos/${encodedRepository}/issues/${encodedId}`, {
          method: "PATCH",
          headers: {"content-type": "application/json", "if-match": `"${issue.version}"`},
          body: JSON.stringify({title: titleInput.value, body: bodyInput.value}),
        });
        if (!response.ok) throw new Error("issue edit failed");
        await showIssue(repository, id);
      } catch (_error) {
        editButton.disabled = false;
        editStatus.className = "form-status is-error";
        editStatus.textContent = "Issue could not be updated.";
      }
    });
    description.append(descriptionHeader, renderedBody, edit);
    main.append(description);

    for (const comment of comments) {
      const item = document.createElement("article");
      item.className = "timeline-card issue-comment";
      const header = document.createElement("header");
      header.append(createAvatar(comment.actor));
      const meta = document.createElement("p");
      const commenter = document.createElement("strong");
      commenter.textContent = comment.actor || "unknown";
      meta.append(commenter, document.createTextNode(` commented ${formatRelativeTimestamp(comment.created_at)}`));
      header.append(meta);
      const text = document.createElement("div");
      text.className = "timeline-body";
      const paragraph = document.createElement("p");
      paragraph.textContent = comment.body;
      text.append(paragraph);
      item.append(header, text);
      main.append(item);
    }

    const composer = document.createElement("form");
    composer.className = "comment-composer";
    const composerAvatar = createAvatar("H");
    const composerCard = document.createElement("div");
    composerCard.className = "comment-composer-card";
    const commentLabel = document.createElement("label");
    commentLabel.htmlFor = "issue-comment-body";
    commentLabel.textContent = "Add a comment";
    const commentBody = document.createElement("textarea");
    commentBody.id = "issue-comment-body";
    commentBody.required = true;
    commentBody.rows = 5;
    commentBody.placeholder = "Leave a comment";
    const composerFooter = document.createElement("div");
    composerFooter.className = "composer-footer";
    const commentStatus = document.createElement("p");
    commentStatus.className = "form-status";
    commentStatus.setAttribute("role", "status");
    const actionGroup = document.createElement("div");
    actionGroup.className = "form-actions";
    const stateAction = document.createElement("button");
    stateAction.className = "button button-secondary";
    stateAction.type = "button";
    const nextState = issue.state === "open" ? "closed" : "open";
    stateAction.textContent = nextState === "closed" ? "Close issue" : "Reopen issue";
    stateAction.addEventListener("click", async () => {
      stateAction.disabled = true;
      try {
        const response = await fetch(`/api/repos/${encodedRepository}/issues/${encodedId}`, {
          method: "PATCH",
          headers: {"content-type": "application/json", "if-match": `"${issue.version}"`},
          body: JSON.stringify({state: nextState}),
        });
        if (!response.ok) throw new Error("issue state update failed");
        await showIssue(repository, id);
      } catch (_error) {
        stateAction.disabled = false;
        stateAction.textContent = "Update failed; try again";
      }
    });
    const commentButton = document.createElement("button");
    commentButton.className = "button";
    commentButton.type = "submit";
    commentButton.textContent = "Comment";
    actionGroup.append(stateAction, commentButton);
    composerFooter.append(commentStatus, actionGroup);
    composerCard.append(commentLabel, commentBody, composerFooter);
    composer.append(composerAvatar, composerCard);
    composer.addEventListener("submit", async (event) => {
      event.preventDefault();
      commentButton.disabled = true;
      try {
        const response = await fetch(`/api/repos/${encodedRepository}/issues/${encodedId}/comments`, {
          method: "POST",
          headers: {"content-type": "application/json"},
          body: JSON.stringify({id: generateInternalId(), body: commentBody.value}),
        });
        if (!response.ok) throw new Error("comment failed");
        await showIssue(repository, id);
      } catch (_error) {
        commentButton.disabled = false;
        commentStatus.className = "form-status is-error";
        commentStatus.textContent = "Comment could not be added.";
      }
    });
    main.append(composer);

    const mutateMetadata = async (resource, method, value) => {
      const suffix = method === "DELETE" ? `/${encodeURIComponent(value)}` : "";
      const field = resource === "labels" ? "label" : "actor";
      const request = {method, headers: {"content-type": "application/json"}};
      if (method === "POST") request.body = JSON.stringify({[field]: value});
      const response = await fetch(
        `/api/repos/${encodedRepository}/issues/${encodedId}/${resource}${suffix}`,
        request,
      );
      if (!response.ok) return false;
      await showIssue(repository, id);
      return true;
    };
    const sidebar = createMetadataSidebar([
      ["Assignees", createTokenEditor({
        name: "assignee",
        values: assignees,
        emptyMessage: "No one assigned",
        placeholder: "Assign a person",
        onAdd: (value) => mutateMetadata("assignees", "POST", value),
        onRemove: (value) => mutateMetadata("assignees", "DELETE", value),
      })],
      ["Labels", createTokenEditor({
        name: "label",
        values: labels,
        emptyMessage: "None yet",
        placeholder: "Add a label",
        onAdd: (value) => mutateMetadata("labels", "POST", value),
        onRemove: (value) => mutateMetadata("labels", "DELETE", value),
      })],
    ]);
    layout.append(main, sidebar);
    dashboard.append(summary, layout);
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
  pageLede.textContent = `${repository} · compare changes across branches.`;
  dashboard.replaceChildren();
  const submissionKey = generateInternalId();
  const form = document.createElement("form");
  form.className = "repository-form pull-request-form create-pull-form";
  const heading = document.createElement("h2");
  heading.textContent = "Compare changes";
  const hint = document.createElement("p");
  hint.className = "muted-message";
  hint.textContent = "Choose a base branch, then select the branch with your changes.";
  const chooser = document.createElement("div");
  chooser.className = "branch-compare-chooser";
  const baseGroup = document.createElement("div");
  const baseLabel = document.createElement("label");
  baseLabel.htmlFor = "pull-target-ref";
  baseLabel.textContent = "Base";
  const base = document.createElement("select");
  base.id = "pull-target-ref";
  base.required = true;
  baseGroup.append(baseLabel, base);
  const arrow = document.createElement("span");
  arrow.className = "branch-compare-arrow";
  arrow.setAttribute("aria-hidden", "true");
  arrow.textContent = "←";
  const sourceGroup = document.createElement("div");
  const sourceLabel = document.createElement("label");
  sourceLabel.htmlFor = "pull-source-ref";
  sourceLabel.textContent = "Compare";
  const source = document.createElement("select");
  source.id = "pull-source-ref";
  source.required = true;
  sourceGroup.append(sourceLabel, source);
  chooser.append(baseGroup, arrow, sourceGroup);
  const preview = document.createElement("section");
  preview.className = "pull-create-preview";
  const previewTitle = document.createElement("h3");
  previewTitle.textContent = "Select branches to preview this pull request";
  const previewText = document.createElement("p");
  previewText.textContent = "The pull request title will be based on the selected branches.";
  preview.append(previewTitle, previewText);
  const actions = document.createElement("div");
  actions.className = "form-actions";
  const cancel = document.createElement("a");
  cancel.className = "button button-secondary";
  cancel.href = `/ui/repos/${encodeURIComponent(repository)}/pulls`;
  cancel.textContent = "Cancel";
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Create pull request";
  actions.append(cancel, submit);
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  form.append(heading, hint, chooser, preview, actions, status);
  dashboard.append(form);
  try {
    const encoded = encodeURIComponent(repository);
    const response = await fetch(`/api/repos/${encoded}/branches`, {headers: {accept: "application/json"}});
    if (!response.ok) throw new Error("branches unavailable");
    const branches = await response.json();
    if (!branches.length) throw new Error("no branches");
    for (const branch of branches) {
      for (const select of [base, source]) {
        const option = document.createElement("option");
        option.value = branch.name;
        option.textContent = shortReference(branch.name);
        option.dataset.oid = branch.oid;
        select.append(option);
      }
    }
    const query = new URLSearchParams(window.location.search);
    const requestedBase = query.get("target") || query.get("base");
    const requestedSource = query.get("source") || query.get("head");
    const mainBranch = branches.find((branch) => branch.name === "refs/heads/main");
    if (mainBranch) base.value = mainBranch.name;
    if (requestedBase && branches.some((branch) => branch.name === requestedBase)) base.value = requestedBase;
    const comparisonBranch = branches.find((branch) => branch.name !== base.value);
    if (comparisonBranch) source.value = comparisonBranch.name;
    if (requestedSource && branches.some((branch) => branch.name === requestedSource)) source.value = requestedSource;
    const updatePreview = () => {
      previewTitle.textContent = `${shortReference(source.value)} into ${shortReference(base.value)}`;
      const sameBranch = source.value === base.value;
      previewText.textContent = sameBranch
        ? "Choose two different branches to create a pull request."
        : `Changes from ${shortReference(source.value)} will be proposed for ${shortReference(base.value)}.`;
      submit.disabled = sameBranch;
    };
    base.addEventListener("change", updatePreview);
    source.addEventListener("change", updatePreview);
    updatePreview();
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      submit.disabled = true;
      status.textContent = "Creating pull request...";
      const baseBranch = branches.find((branch) => branch.name === base.value);
      const sourceBranch = branches.find((branch) => branch.name === source.value);
      try {
        const create = await fetch(`/api/repos/${encoded}/pulls`, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "idempotency-key": submissionKey,
          },
          body: JSON.stringify({
            source_ref: sourceBranch.name,
            target_ref: baseBranch.name,
            base_oid: baseBranch.oid,
            head_oid: sourceBranch.oid,
          }),
        });
        const created = await create.json();
        if (!create.ok) throw new Error(created.detail || "create failed");
        window.location.href = `/ui/repos/${encoded}/pulls/${encodeURIComponent(created.id)}`;
      } catch (error) {
        submit.disabled = false;
        status.className = "form-status is-error";
        status.textContent = error.message || "Pull request could not be created.";
      }
    });
  } catch (_error) {
    submit.disabled = true;
    status.className = "form-status is-error";
    status.textContent = "Branches could not be loaded. Create at least two branches first.";
  }
}

function createCompareSummary(payload) {
  const summary = document.createElement("p");
  summary.className = "compare-summary";
  const files = Array.isArray(payload?.files) ? payload.files.length : 0;
  const additions = Number(payload?.additions || 0);
  const deletions = Number(payload?.deletions || 0);
  summary.textContent = files
    ? `${files} changed ${files === 1 ? "file" : "files"} with ${additions} ${additions === 1 ? "addition" : "additions"} and ${deletions} ${deletions === 1 ? "deletion" : "deletions"}.`
    : "These references point at the same content.";
  return summary;
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
  const results = document.createElement("div");
  results.className = "compare-results";
  dashboard.append(form, results);
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
        results.replaceChildren(
          createCompareSummary(payload), renderUnifiedDiffSafe(payload),
        );
        const mergeButton = document.createElement("button");
        mergeButton.className = "button merge-button";
        mergeButton.type = "button";
        mergeButton.textContent = "Merge pull request";
        mergeButton.disabled = true;
        mergeButton.setAttribute("aria-describedby", "compare-status");
        status.className = "form-status";
        status.id = "compare-status";
        status.textContent = `${base.value} compared with ${head.value}. Open a pull request to enable merging.`;
        results.append(mergeButton);
      } catch (_error) {
        results.replaceChildren();
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
  link.className = "tree-entry-link";
  const entryPath = path ? `${path}/${entry.name}` : entry.name;
  link.href = entry.type === "tree"
    ? `/ui/repos/${encodeURIComponent(repository)}/files/${encodeURIComponent(branch)}/${encodeURIComponent(entryPath)}`
    : `/ui/repos/${encodeURIComponent(repository)}/blob/${encodeURIComponent(branch)}/${encodeURIComponent(entryPath)}`;
  const icon = document.createElement("span");
  icon.className = `tree-entry-icon ${entry.type === "tree" ? "is-tree" : "is-blob"}`;
  icon.setAttribute("aria-hidden", "true");
  link.append(icon, document.createTextNode(entry.name));
  item.append(link);
  if (entry.last_commit || entry.last_commit_at !== undefined) {
    const metadata = document.createElement("span");
    metadata.className = "tree-entry-meta";
    if (entry.last_commit) {
      const summary = document.createElement("span");
      summary.className = "entry-summary";
      summary.textContent = entry.last_commit;
      metadata.append(summary);
    }
    if (entry.last_commit_at !== undefined) {
      const timestampDate = commitTimestampDate(entry.last_commit_at);
      const timestamp = document.createElement("time");
      timestamp.className = "tree-entry-time";
      if (timestampDate) timestamp.dateTime = timestampDate.toISOString();
      timestamp.textContent = formatCommitTimestamp(entry.last_commit_at);
      metadata.append(timestamp);
    }
    item.append(metadata);
  }
  return item;
}

function commitTimestampDate(value) {
  const raw = String(value ?? "");
  const compact = raw.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/);
  if (compact) {
    const date = new Date(Date.UTC(
      Number(compact[1]), Number(compact[2]) - 1, Number(compact[3]),
      Number(compact[4]), Number(compact[5]), Number(compact[6]),
    ));
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (/^-?\d+$/.test(raw)) {
    const date = new Date(Number(raw) * 1000);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  const date = new Date(raw);
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatCommitTimestamp(value) {
  const date = commitTimestampDate(value);
  if (!date) return String(value);
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
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
  const list = document.createElement("ul");
  list.className = "tree-list";
  const browserHeader = document.createElement("div");
  browserHeader.className = "file-browser-header";
  const breadcrumb = document.createElement("nav");
  breadcrumb.className = "breadcrumb";
  breadcrumb.setAttribute("aria-label", "File path");
  const rootLink = document.createElement("a");
  rootLink.href = `/ui/repos/${encodeURIComponent(repository)}/files/${encodeURIComponent(branch)}`;
  rootLink.textContent = repository;
  breadcrumb.append(rootLink, " / ");
  const branchLabel = document.createElement("span");
  branchLabel.className = "breadcrumb-branch";
  branchLabel.textContent = branch;
  breadcrumb.append(branchLabel);
  let accumulatedPath = "";
  path.split("/").filter(Boolean).forEach((part, index, parts) => {
    accumulatedPath = accumulatedPath ? `${accumulatedPath}/${part}` : part;
    breadcrumb.append(" / ");
    if (index === parts.length - 1) {
      const current = document.createElement("strong");
      current.textContent = part;
      breadcrumb.append(current);
    } else {
      const link = document.createElement("a");
      const encodedPartPath = accumulatedPath.split("/").map(encodeURIComponent).join("/");
      link.href = `/ui/repos/${encodeURIComponent(repository)}/files/${encodeURIComponent(branch)}/${encodedPartPath}`;
      link.textContent = part;
      breadcrumb.append(link);
    }
  });
  const browserActions = document.createElement("div");
  browserActions.className = "file-browser-actions";
  const overviewLink = document.createElement("a");
  overviewLink.className = "button button-secondary";
  overviewLink.href = `/ui/repos/${encodeURIComponent(repository)}`;
  overviewLink.textContent = "Overview";
  const historyLink = document.createElement("a");
  historyLink.className = "button button-secondary";
  historyLink.href = `/ui/repos/${encodeURIComponent(repository)}/commits/${encodeURIComponent(branch)}`;
  historyLink.textContent = "History";
  browserActions.append(
    overviewLink, historyLink,
    createCodeMenu(`${window.location.origin}/${repository}.git`),
  );
  browserHeader.append(breadcrumb, browserActions);
  const loading = document.createElement("li");
  loading.className = "muted-message";
  loading.textContent = "Loading files…";
  list.append(loading);
  dashboard.append(browserHeader, list);
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

function createFileEditor(context) {
  const {repository, branch, path, source, head, onCancel} = context;
  const encoded = encodeURIComponent(repository);
  const encodedPath = path.split("/").map(encodeURIComponent).join("/");
  const form = document.createElement("form");
  form.className = "file-editor";
  const editorLabel = document.createElement("label");
  editorLabel.htmlFor = "file-editor-content";
  editorLabel.className = "sr-only";
  editorLabel.textContent = `Contents of ${path}`;
  const editor = document.createElement("textarea");
  editor.id = "file-editor-content";
  editor.className = "file-editor-content";
  editor.spellcheck = false;
  editor.rows = Math.min(Math.max(source.split("\n").length + 2, 12), 40);
  editor.value = source;
  const commitBox = document.createElement("section");
  commitBox.className = "commit-box";
  const commitHeading = document.createElement("h2");
  commitHeading.textContent = "Commit changes";
  const messageLabel = document.createElement("label");
  messageLabel.htmlFor = "file-editor-message";
  messageLabel.textContent = "Commit message";
  const message = document.createElement("input");
  message.id = "file-editor-message";
  message.required = true;
  message.maxLength = 255;
  message.value = `Update ${path.split("/").pop()}`;
  const target = document.createElement("p");
  target.className = "muted-message";
  target.textContent = `Commits directly to the ${branch} branch.`;
  const actions = document.createElement("div");
  actions.className = "form-actions";
  const cancel = document.createElement("button");
  cancel.className = "button button-secondary";
  cancel.type = "button";
  cancel.textContent = "Cancel";
  cancel.addEventListener("click", onCancel);
  const submit = document.createElement("button");
  submit.className = "button";
  submit.type = "submit";
  submit.textContent = "Commit changes";
  actions.append(cancel, submit);
  const status = document.createElement("p");
  status.className = "form-status";
  status.setAttribute("role", "status");
  status.setAttribute("aria-live", "polite");
  commitBox.append(commitHeading, messageLabel, message, target, actions, status);
  form.append(editorLabel, editor, commitBox);
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (editor.value === source) {
      status.className = "form-status is-error";
      status.textContent = "This file has no changes to commit.";
      return;
    }
    submit.disabled = true;
    status.className = "form-status";
    status.textContent = "Committing…";
    try {
      const response = await fetch(`/api/repos/${encoded}/contents/${encodedPath}`, {
        method: "PUT",
        headers: {"content-type": "application/json"},
        body: JSON.stringify({
          ref: branch,
          content: editor.value,
          message: message.value,
          expected_head_oid: head,
        }),
      });
      const body = await response.json().catch(() => null);
      if (!response.ok) throw new Error(body?.detail || `commit returned ${response.status}`);
      window.location.href =
        `/ui/repos/${encoded}/blob/${encodeURIComponent(branch)}/${encodedPath}`;
    } catch (error) {
      submit.disabled = false;
      status.className = "form-status is-error";
      status.textContent = error.message || "The file could not be committed.";
    }
  });
  return {form, focus: () => editor.focus()};
}

async function showBlobViewer(repository, branch, path) {
  pageTitle.textContent = path.split("/").pop() || "Blob";
  pageLede.textContent = `${repository} · ${branch} · ${path}`;
  dashboard.replaceChildren();
  const encoded = encodeURIComponent(repository);
  const encodedPath = path.split("/").map(encodeURIComponent).join("/");
  const rawUrl = `/api/repos/${encoded}/contents/${encodedPath}?ref=${encodeURIComponent(branch)}&format=raw`;
  const actions = document.createElement("p");
  actions.className = "blob-actions";
  const edit = document.createElement("button");
  edit.className = "button button-secondary edit-file";
  edit.type = "button";
  edit.hidden = true;
  edit.append(interfaceIcon("pencil"), document.createTextNode("Edit this file"));
  const download = document.createElement("a");
  download.className = "button raw-download";
  download.href = rawUrl;
  download.download = path.split("/").pop() || "download";
  download.textContent = "Download raw";
  actions.append(edit, download);
  const viewer = document.createElement("pre");
  viewer.className = "blob-viewer";
  viewer.textContent = "Loading file…";
  dashboard.append(actions, viewer);
  try {
    const [response, branchesResponse] = await Promise.all([
      fetch(rawUrl),
      fetch(`/api/repos/${encoded}/branches`),
    ]);
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
    const source = await response.text();
    renderSourceSafe(viewer, source, path);
    // Only branches can be committed to, so tags and detached refs stay read-only.
    const branches = branchesResponse.ok ? await branchesResponse.json() : [];
    const head = branches.find((reference) => reference.name === branch
      || reference.name === `refs/heads/${branch}`);
    if (!head) return;
    edit.hidden = false;
    edit.addEventListener("click", () => {
      const editor = createFileEditor({
        repository,
        branch,
        path,
        source,
        head: head.oid,
        onCancel: () => {
          editor.form.replaceWith(viewer);
          edit.hidden = false;
          edit.focus();
        },
      });
      edit.hidden = true;
      viewer.replaceWith(editor.form);
      editor.focus();
    });
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
