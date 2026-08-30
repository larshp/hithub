import {expect, test} from "@playwright/test";
import {readFile} from "node:fs/promises";
import {fileURLToPath} from "node:url";
import {join} from "node:path";

const fixtureRoot = fileURLToPath(new URL("../integration/fixtures/abapgit-fixture/", import.meta.url));
const fixtureFiles = [
  ".abapgit.xml",
  "src/package.devc.xml",
  "src/zcl_hithub_fixture.clas.xml",
  "src/zcl_hithub_fixture.clas.abap",
];

async function json(route, body, status = 200) {
  await route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("creates a repository from the browser", async ({page}) => {
  await page.route("**/api/repos", async (route) => {
    if (route.request().method() === "POST") {
      await json(route, {
        id: "repo-1",
        name: "browser-repository",
        description: "Created in a browser test.",
        default_branch: "main",
        version: 1,
      }, 201);
      return;
    }
    await json(route, []);
  });
  await page.goto("/ui/create");
  await expect(page.locator("#repository-name")).toBeFocused();
  await page.locator("#repository-name").fill("browser-repository");
  await page.locator("#repository-description").fill("Created in a browser test.");
  await page.getByRole("button", {name: "Create repository"}).click();
  await page.waitForURL(/\/ui\/repos\/browser-repository$/);
});

test("a caller creates a repository through the real web UI", async ({page}, testInfo) => {
  const name = `e2e-${Date.now()}-${testInfo.workerIndex}`;
  await page.goto("/ui/create");
  await page.locator("#repository-name").fill(name);
  await page.getByRole("button", {name: "Create repository"}).click();
  await page.waitForURL(new RegExp(`/ui/repos/${name}$`));
});

test("the repository overview displays its clone URL in the Code menu", async ({page}, testInfo) => {
  const name = `clone-${Date.now()}-${testInfo.workerIndex}`;
  await page.goto("/ui/create");
  await page.locator("#repository-name").fill(name);
  await page.getByRole("button", {name: "Create repository"}).click();
  await page.waitForURL(new RegExp(`/ui/repos/${name}$`));
  await page.locator(".code-menu summary").click();
  const cloneUrl = `${new URL(page.url()).origin}/${name}.git`;
  await expect(page.locator(".clone-field input")).toHaveValue(cloneUrl);
  const discovery = await page.request.get(
    `${cloneUrl}/info/refs?service=git-upload-pack`,
  );
  expect(discovery.status()).toBe(200);
  expect(await discovery.text()).toContain("refs/heads/main");
  await expect(page.getByRole("button", {name: "Copy clone URL"})).toBeVisible();
  await expect(page.locator(".readme-content")).toContainText(name);
  await expect(page.locator(".repository-contents")).toContainText("README.md");
  await expect(page.getByText("Files on main")).toHaveCount(0);
  await expect(page.locator("#tags")).toHaveCount(0);
  await expect(page.getByText("Recent activity")).toHaveCount(0);
  await page.goto(`/ui/repos/${name}/files/main`);
  await expect(page.locator(".tree-list")).toContainText("README.md");
  await page.goto(`/ui/repos/${name}/commits/main`);
  await expect(page.locator(".commit-list")).toContainText("Initial commit");
  await page.getByRole("link", {name: "Initial commit"}).click();
  await expect(page.locator(".commit-message")).toContainText("Initial commit");
});

test("browses every object in the abapGit interoperability fixture", async ({page}) => {
  const contents = new Map();
  for (const path of fixtureFiles) contents.set(path, await readFile(join(fixtureRoot, path), "utf8"));
  await page.route("**/api/repos/fixture", async (route) => json(route, {
    id: "fixture-1", name: "fixture", description: "abapGit fixture",
    default_branch: "main", version: 1,
  }));
  await page.route("**/api/repos/fixture/branches", async (route) => json(route, [
    {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
  ]));
  await page.route("**/api/repos/fixture/tags", async (route) => json(route, []));
  await page.route("**/api/repos/fixture/contents/**", async (route) => {
    const requestUrl = new URL(route.request().url());
    const requestPath = requestUrl.pathname;
    const path = requestPath.split("/contents/")[1];
    if (requestUrl.searchParams.get("format") === "raw") {
      await route.fulfill({status: 200, contentType: "text/plain", body: contents.get(path) || ""});
      return;
    }
    const entries = requestPath.endsWith("/contents/src")
      ? fixtureFiles.slice(1).map((file) => ({name: file.slice(4), type: "blob"}))
      : [
        {name: ".abapgit.xml", type: "blob"},
        {name: "src", type: "tree"},
      ];
    await json(route, {entries});
  });
  await page.goto("/ui/repos/fixture/files/main");
  await expect(page.locator(".tree-list")).toContainText(".abapgit.xml");
  await page.goto("/ui/repos/fixture/files/main/src");
  await expect(page.locator(".tree-list")).toContainText("zcl_hithub_fixture.clas.abap");
  for (const path of fixtureFiles) {
    await page.goto(`/ui/repos/fixture/blob/main/${path}`);
    await expect(page.locator(".source-code")).toContainText(contents.get(path).trim().split("\n")[0]);
  }
});

test("browses a repository tree", async ({page}) => {
  await page.route("**/api/repos/demo", async (route) => json(route, {
    id: "repo-1", name: "demo", description: "Demo repository",
    default_branch: "main", version: 1,
  }));
  await page.route("**/api/repos/demo/branches", async (route) => json(route, [
    {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
  ]));
  await page.route("**/api/repos/demo/tags", async (route) => json(route, []));
  await page.route("**/api/repos/demo/contents/**", async (route) => json(route, {
    entries: [
      {name: "README.md", type: "blob", last_commit: "Document the project", last_commit_at: 1704067200},
      {name: "src", type: "tree", last_commit: "Add source", last_commit_at: 1704067200},
    ],
  }));
  await page.goto("/ui/repos/demo");
  await expect(page.locator(".ref-switcher-name")).toHaveText("main");
  await expect(page.locator(".contents-commit")).toContainText("Document the project");
  await expect(page.locator(".tree-entry-time")).toHaveCount(2);
  await expect(page.getByRole("button", {name: "Go to file"})).toHaveCount(0);
  await expect(page.getByRole("searchbox", {name: "Filter files"})).toHaveCount(0);
  await page.locator(".ref-switcher-summary").click();
  await page.locator("#ref-panel-branches .ref-item").click();
  await expect(page).toHaveURL(/\/ui\/repos\/demo\/files\/main$/);
  await expect(page.locator(".tree-list")).toContainText("README.md");
  await expect(page.locator(".tree-list")).toContainText("src");
});

test("filters branches and tags in the reference switcher", async ({page}) => {
  await page.route("**/api/repos/demo", async (route) => json(route, {
    id: "repo-1", name: "demo", description: "Demo repository",
    default_branch: "main", version: 1,
  }));
  await page.route("**/api/repos/demo/branches", async (route) => json(route, [
    {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
    {name: "refs/heads/hvam/forms2408", oid: "b".repeat(40), algorithm: "sha1", version: 1},
    {name: "refs/heads/hvam/generic2708", oid: "c".repeat(40), algorithm: "sha1", version: 1},
  ]));
  await page.route("**/api/repos/demo/tags", async (route) => json(route, [
    {name: "refs/tags/v1.0.0", oid: "d".repeat(40), algorithm: "sha1", version: 1},
  ]));
  await page.route("**/api/repos/demo/contents/**", async (route) => json(route, {entries: []}));
  await page.goto("/ui/repos/demo");
  await page.locator(".ref-switcher-summary").click();
  await expect(page.getByText("Switch branches/tags")).toBeVisible();
  await expect(page.locator("#ref-panel-branches .ref-item:visible")).toHaveCount(3);
  await expect(page.locator(".ref-item", {hasText: "main"}).locator(".ref-item-badge"))
    .toHaveText("default");
  await page.getByLabel("Find or create a branch").fill("forms");
  await expect(page.locator("#ref-panel-branches .ref-item:visible")).toHaveCount(1);
  await expect(page.locator("#ref-panel-branches .ref-item:visible"))
    .toContainText("hvam/forms2408");
  await expect(page.locator(".ref-create")).toBeVisible();
  await expect(page.locator(".ref-create")).toContainText("Create branch forms from main");
  await page.getByLabel("Find or create a branch").fill("main");
  await expect(page.locator(".ref-create")).toBeHidden();
  await page.getByRole("tab", {name: "Tags"}).click();
  await expect(page.getByLabel("Find a tag")).toBeVisible();
  await expect(page.locator(".ref-create")).toBeHidden();
  await page.getByLabel("Find a tag").fill("v1");
  await expect(page.locator("#ref-panel-tags .ref-item:visible")).toHaveCount(1);
  await page.locator("#ref-panel-tags .ref-item:visible").click();
  await expect(page).toHaveURL(/\/ui\/repos\/demo\/files\/v1\.0\.0$/);
});

test("creates a branch from the reference switcher", async ({page}) => {
  let created = null;
  await page.route("**/api/repos/demo", async (route) => json(route, {
    id: "repo-1", name: "demo", description: "Demo repository",
    default_branch: "main", version: 1,
  }));
  await page.route("**/api/repos/demo/branches", async (route) => {
    if (route.request().method() === "POST") {
      created = route.request().postDataJSON();
      await json(route, {
        name: `refs/heads/${created.name}`, oid: created.oid,
        algorithm: "sha1", version: 1,
      }, 201);
      return;
    }
    await json(route, [
      {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
    ]);
  });
  await page.route("**/api/repos/demo/tags", async (route) => json(route, []));
  await page.route("**/api/repos/demo/contents/**", async (route) => json(route, {entries: []}));
  await page.goto("/ui/repos/demo");
  await page.locator(".ref-switcher-summary").click();
  await page.getByLabel("Find or create a branch").fill("feature/switcher");
  await page.getByRole("button", {name: /Create branch feature\/switcher/}).click();
  await page.waitForURL(/\/ui\/repos\/demo\/files\/feature%2Fswitcher$/);
  expect(created.name).toBe("feature/switcher");
  expect(created.oid).toBe("a".repeat(40));
});

test("reports a rejected branch name in the reference switcher", async ({page}) => {
  await page.route("**/api/repos/demo", async (route) => json(route, {
    id: "repo-1", name: "demo", description: "Demo repository",
    default_branch: "main", version: 1,
  }));
  await page.route("**/api/repos/demo/branches", async (route) => {
    if (route.request().method() === "POST") {
      await route.fulfill({
        status: 400,
        contentType: "application/problem+json",
        body: JSON.stringify({
          type: "about:blank", title: "Bad Request", status: 400,
          detail: "Branch name is not valid.", instance: "/api/repos/demo/branches",
        }),
      });
      return;
    }
    await json(route, [
      {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
    ]);
  });
  await page.route("**/api/repos/demo/tags", async (route) => json(route, []));
  await page.route("**/api/repos/demo/contents/**", async (route) => json(route, {entries: []}));
  await page.goto("/ui/repos/demo");
  await page.locator(".ref-switcher-summary").click();
  await page.getByLabel("Find or create a branch").fill("bad..name");
  await page.getByRole("button", {name: /Create branch bad\.\.name/}).click();
  await expect(page.locator(".ref-status")).toContainText("Branch name is not valid.");
  await expect(page).toHaveURL(/\/ui\/repos\/demo$/);
});

test("shows the supported repository navigation and pull requests", async ({page}) => {
  await page.route("**/api/repos/demo/issues", async (route) => json(route, []));
  await page.route("**/api/repos/demo/pulls", async (route) => json(route, [
    {
      id: "pull-1", state: "open", source_ref: "refs/heads/feature",
      target_ref: "refs/heads/main", base_oid: "base", head_oid: "head", version: 1,
    },
  ]));
  await page.goto("/ui/repos/demo/pulls");
  await expect(page.locator(".repository-tabs")).toContainText("CodeIssues0Pull requests1More");
  await expect(page.locator(".repository-tab.is-active")).toContainText("Pull requests");
  await expect(page.locator(".repository-type-badge")).toHaveCount(0);
  await page.locator(".repository-more > summary").click();
  await expect(page.getByRole("link", {name: "Audit"})).toBeVisible();
  await expect(page.locator(".pull-request-list")).toContainText("feature into main");
  await expect(page.locator(".pull-request-list")).toContainText("#pull-1");
  await expect(page.getByRole("link", {name: "New pull request"})).toHaveAttribute(
    "href", "/ui/repos/demo/pulls/new",
  );
});

test("keeps secondary repository navigation in More on mobile", async ({page}) => {
  await page.setViewportSize({width: 390, height: 844});
  await page.route("**/api/repos/demo/issues", async (route) => json(route, []));
  await page.route("**/api/repos/demo/pulls", async (route) => json(route, []));
  await page.goto("/ui/repos/demo/issues");
  await expect(page.locator(".repository-more > summary")).toBeVisible();
  await page.locator(".repository-more > summary").click();
  await expect(page.getByRole("link", {name: "Audit"})).toBeVisible();
  expect(await page.evaluate(
    () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
  )).toBe(true);
});

test("filters compact issue rows by state and search", async ({page}) => {
  await page.route("**/api/repos/demo/issues", async (route) => json(route, [
    {
      id: "12", title: "Open keyboard shortcuts", body: "", state: "open",
      actor: "alice", created_at: "20260830120000", updated_at: "20260830120000", version: 1,
    },
    {
      id: "11", title: "Retired navigation", body: "", state: "closed",
      actor: "bob", created_at: "20260829120000", updated_at: "20260829120000", version: 2,
    },
  ]));
  await page.goto("/ui/repos/demo/issues");
  await expect(page.getByRole("link", {name: "Open keyboard shortcuts"})).toBeVisible();
  await expect(page.getByRole("link", {name: "Retired navigation"})).toHaveCount(0);
  await page.getByRole("button", {name: "1 Closed"}).click();
  await expect(page.getByRole("link", {name: "Retired navigation"})).toBeVisible();
  await page.getByRole("searchbox", {name: "Search issues"}).fill("missing");
  await expect(page.getByRole("heading", {name: "No results matched your search"})).toBeVisible();
});

test("numbers issues sequentially through the real web UI", async ({page}, testInfo) => {
  const name = `numbered-${Date.now()}-${testInfo.workerIndex}`;
  expect((await page.request.post("/api/repos", {data: {name}})).status()).toBe(201);
  for (const [index, title] of [[1, "First reported"], [2, "Second reported"]]) {
    await page.goto(`/ui/repos/${name}/issues/new`);
    await page.getByLabel("Title").fill(title);
    await page.getByRole("button", {name: "Create issue"}).click();
    await page.waitForURL(new RegExp(`/ui/repos/${name}/issues/${index}$`));
    await expect(page.locator(".detail-title-line")).toContainText(`#${index}`);
  }
  await page.goto(`/ui/repos/${name}/issues`);
  const rows = page.locator(".work-row-content p");
  await expect(rows.first()).toContainText("#2");
  await expect(rows.last()).toContainText("#1");
  await page.getByRole("link", {name: "First reported"}).click();
  await expect(page).toHaveURL(new RegExp(`/ui/repos/${name}/issues/1$`));
});

test("shows pull request conversation and changed files tabs", async ({page}) => {
  await page.route("**/api/repos/demo/pulls/pull-1", async (route) => json(route, {
    id: "pull-1", state: "draft", source_ref: "refs/heads/feature",
    target_ref: "refs/heads/main", base_oid: "base", head_oid: "head", version: 1,
  }));
  await page.route("**/api/repos/demo/pulls/pull-1/reviews", async (route) => json(route, [
    {
      id: "review-1", actor: "carol", state: "request_changes",
      body: "Please rename the helper", created_at: "20260830120000",
    },
  ]));
  await page.route("**/api/repos/demo/pulls/pull-1/comments", async (route) => json(route, [
    {id: "comment-1", actor: "dave", body: "Nice cleanup", created_at: "20260830110000"},
  ]));
  await page.route("**/api/repos/demo/compare?*", async (route) => json(route, {
    files: [{path: "README", patch: "@@ -1 +1 @@\n-old line\n+new line"}],
    additions: 1, deletions: 1, summary: {added: 0, modified: 1, deleted: 0, total: 1},
  }));
  await page.goto("/ui/repos/demo/pulls/pull-1");
  await expect(page.getByRole("heading", {name: "feature into main"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Ready for review"})).toBeVisible();
  await expect(page.locator(".pull-comment")).toContainText("Nice cleanup");
  await expect(page.locator(".pull-review")).toContainText("Please rename the helper");
  await expect(page.locator(".pull-review .review-state")).toContainText("Requested changes");
  await expect(page.locator(".metadata-sidebar")).toContainText("carol");
  await page.getByRole("button", {name: "Files changed"}).click();
  await expect(page.locator(".diff-viewer")).toContainText("new line");
  await page.getByRole("button", {name: "Conversation"}).click();
  await expect(page.locator(".merge-box")).toBeVisible();
});

test("submits a pull request review from the conversation tab", async ({page}) => {
  await page.route("**/api/repos/demo/pulls/pull-2", async (route) => json(route, {
    id: "pull-2", state: "open", source_ref: "refs/heads/feature",
    target_ref: "refs/heads/main", base_oid: "base", head_oid: "head", version: 1,
  }));
  const submitted = [];
  await page.route("**/api/repos/demo/pulls/pull-2/reviews", async (route) => {
    if (route.request().method() === "POST") {
      submitted.push(route.request().postDataJSON());
      await json(route, submitted[submitted.length - 1], 201);
      return;
    }
    await json(route, submitted.map((review) => ({
      ...review, actor: "local-development", created_at: "20260830130000",
    })));
  });
  await page.route("**/api/repos/demo/pulls/pull-2/comments", async (route) => json(route, []));
  await page.goto("/ui/repos/demo/pulls/pull-2");
  await page.getByLabel("Add a comment").fill("Ship it");
  await page.getByLabel("Review verdict").selectOption("approved");
  await page.getByRole("button", {name: "Submit"}).click();
  await expect(page.locator(".pull-review")).toContainText("Ship it");
  expect(submitted[0].state).toBe("approved");
  expect(submitted[0].body).toBe("Ship it");
});

test("edits issue labels and assignees from the sidebar", async ({page}) => {
  const labels = [];
  const assignees = ["alice"];
  await page.route("**/api/repos/demo/issues/issue-1", async (route) => json(route, {
    id: "issue-1", title: "Sidebar issue", body: "", state: "open", actor: "alice",
    created_at: "20260830120000", updated_at: "20260830120000", version: 1,
  }));
  await page.route("**/api/repos/demo/issues/issue-1/comments", async (route) => json(route, []));
  await page.route("**/api/repos/demo/issues/issue-1/labels", async (route) => {
    if (route.request().method() === "POST") {
      labels.push(route.request().postDataJSON().label);
      await json(route, {label: labels[labels.length - 1]}, 201);
      return;
    }
    await json(route, labels.map((label) => ({label})));
  });
  await page.route("**/api/repos/demo/issues/issue-1/labels/*", async (route) => {
    labels.splice(0, labels.length);
    await route.fulfill({status: 204, body: ""});
  });
  await page.route("**/api/repos/demo/issues/issue-1/assignees", async (route) => json(
    route, assignees.map((actor) => ({actor})),
  ));
  await page.goto("/ui/repos/demo/issues/issue-1");
  await expect(page.locator(".token", {hasText: "alice"})).toBeVisible();
  await page.getByLabel("Add label").fill("regression");
  await page.locator(".metadata-tokens")
    .filter({has: page.getByLabel("Add label")})
    .getByRole("button", {name: "Add"}).click();
  await expect(page.locator(".token", {hasText: "regression"})).toBeVisible();
  await page.getByRole("button", {name: "Remove label regression"}).click();
  await expect(page.locator(".token", {hasText: "regression"})).toHaveCount(0);
});

test("creates pull requests from branch selections without technical ID fields", async ({page}) => {
  const branches = [
    {name: "refs/heads/feature", oid: "b".repeat(40), algorithm: "sha1", version: 1},
    {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
  ];
  await page.route("**/api/repos/demo/branches", async (route) => json(route, branches));
  let submitted;
  let idempotencyKey;
  await page.route("**/api/repos/demo/pulls", async (route) => {
    if (route.request().method() !== "POST") {
      await json(route, submitted ? [{...submitted, id: "7", state: "draft", version: 1}] : []);
      return;
    }
    submitted = route.request().postDataJSON();
    idempotencyKey = route.request().headers()["idempotency-key"];
    await json(route, {...submitted, id: "7", state: "draft", version: 1}, 201);
  });
  await page.route("**/api/repos/demo/pulls/*", async (route) => json(route, {
    id: "7", state: "draft", source_ref: "refs/heads/feature",
    target_ref: "refs/heads/main", base_oid: "a".repeat(40), head_oid: "b".repeat(40), version: 1,
  }));
  await page.goto("/ui/repos/demo/pulls/new");
  await expect(page.getByLabel("Base")).toHaveValue("refs/heads/main");
  await expect(page.getByLabel("Compare")).toHaveValue("refs/heads/feature");
  await expect(page.getByLabel(/object ID|pull request ID/i)).toHaveCount(0);
  await page.getByRole("button", {name: "Create pull request"}).click();
  await page.waitForURL(/\/pulls\/7$/);
  expect(submitted.source_ref).toBe("refs/heads/feature");
  expect(submitted.target_ref).toBe("refs/heads/main");
  expect(submitted.base_oid).toBe("a".repeat(40));
  expect(submitted.head_oid).toBe("b".repeat(40));
  expect(submitted.id).toBeUndefined();
  expect(idempotencyKey).toBeTruthy();
});

test("shares one number sequence between issues and pull requests", async ({page}, testInfo) => {
  const name = `shared-${Date.now()}-${testInfo.workerIndex}`;
  expect((await page.request.post("/api/repos", {data: {name}})).status()).toBe(201);
  const branches = await (await page.request.get(`/api/repos/${name}/branches`)).json();
  const main = branches[0].oid;
  expect((await page.request.post(`/api/repos/${name}/branches`, {
    data: {name: "feature", oid: main},
  })).status()).toBe(201);

  await page.goto(`/ui/repos/${name}/issues/new`);
  await page.getByLabel("Title").fill("Reported first");
  await page.getByRole("button", {name: "Create issue"}).click();
  await page.waitForURL(new RegExp(`/ui/repos/${name}/issues/1$`));

  await page.goto(`/ui/repos/${name}/pulls/new`);
  await page.getByRole("button", {name: "Create pull request"}).click();
  await page.waitForURL(new RegExp(`/ui/repos/${name}/pulls/2$`));
  await expect(page.locator(".detail-title-line")).toContainText("#2");

  await page.goto(`/ui/repos/${name}/issues/new`);
  await page.getByLabel("Title").fill("Reported after the pull request");
  await page.getByRole("button", {name: "Create issue"}).click();
  await page.waitForURL(new RegExp(`/ui/repos/${name}/issues/3$`));

  const issues = await (await page.request.get(`/api/repos/${name}/issues`)).json();
  const pulls = await (await page.request.get(`/api/repos/${name}/pulls`)).json();
  expect(issues.map((item) => item.id)).toEqual(["3", "1"]);
  expect(pulls.map((item) => item.id)).toEqual(["2"]);
});

test("compares references through the real comparison API", async ({page}) => {
  await page.goto("/ui/repos/compare-fixture/compare");
  await page.locator("#compare-base").selectOption("refs/heads/main");
  await page.locator("#compare-head").selectOption("refs/heads/feature");
  await page.getByRole("button", {name: "Compare"}).click();
  await expect(page.locator(".compare-summary")).toContainText(
    "1 changed file with 1 addition and 1 deletion",
  );
  await expect(page.locator(".diff-viewer")).toContainText("--- a/README");
  await expect(page.locator(".diff-viewer")).toContainText("@@ -1,1 +1,1 @@");
  await expect(page.locator(".diff-viewer .diff-removed")).toContainText("-hello");
  await expect(page.locator(".diff-viewer .diff-added")).toContainText("+feature");
  await page.getByRole("button", {name: "Show split view"}).click();
  await expect(page.locator(".split-diff")).toBeVisible();
  await expect(page.locator(".split-diff .diff-added")).toContainText("feature");
});

test("reports an unchanged comparison without a diff", async ({page}) => {
  await page.goto("/ui/repos/compare-fixture/compare");
  await page.locator("#compare-base").selectOption("refs/heads/main");
  await page.locator("#compare-head").selectOption("refs/heads/main");
  await page.getByRole("button", {name: "Compare"}).click();
  await expect(page.locator(".compare-summary")).toContainText(
    "These references point at the same content",
  );
  await expect(page.locator(".diff-viewer")).toContainText(
    "No textual changes are available",
  );
});

test("falls back for binary and oversized blobs", async ({page}) => {
  await page.route("**/api/repos/demo/contents/**", async (route) => {
    if (route.request().url().includes("binary.bin")) {
      await route.fulfill({
        status: 200,
        contentType: "application/octet-stream",
        body: "binary data",
      });
      return;
    }
    await route.fulfill({
      status: 200,
      contentType: "text/plain",
      headers: {"content-length": "2000000"},
      body: "large text",
    });
  });
  await page.goto("/ui/repos/demo/blob/main/binary.bin");
  await expect(page.locator(".blob-fallback")).toContainText("binary file");
  await page.goto("/ui/repos/demo/blob/main/large.txt");
  await expect(page.locator(".blob-fallback")).toContainText("too large");
});

test("renders supported Markdown without executable markup", async ({page}) => {
  await page.route("**/api/repos/demo", async (route) => json(route, {
    id: "repo-1", name: "demo", description: "Demo repository",
    default_branch: "main", version: 1,
    readme: "# Demo\n\n<img src=x onerror=alert(1)>\n\n```js\nconst safe = true;\n```",
  }));
  await page.route("**/api/repos/demo/branches", async (route) => json(route, []));
  await page.route("**/api/repos/demo/tags", async (route) => json(route, []));
  await page.goto("/ui/repos/demo");
  await expect(page.locator(".readme-content")).toContainText("<img src=x onerror=alert(1)>");
  await expect(page.locator(".readme-content img")).toHaveCount(0);
  await expect(page.locator(".readme-code")).toContainText("const safe = true;");
});
