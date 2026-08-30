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
  await page.locator("#repository-name").fill("browser-repository");
  await page.locator("#repository-description").fill("Created in a browser test.");
  await page.getByRole("button", {name: "Create repository"}).click();
  await expect(page.locator("#form-status")).toContainText("Repository created.");
  await expect(page.locator("#form-status a")).toHaveAttribute(
    "href", "/ui/repos/browser-repository",
  );
});

test("a caller creates a repository through the real web UI", async ({page}, testInfo) => {
  const name = `e2e-${Date.now()}-${testInfo.workerIndex}`;
  await page.goto("/ui/create");
  await page.locator("#repository-name").fill(name);
  await page.getByRole("button", {name: "Create repository"}).click();
  await expect(page.locator("#form-status")).toContainText("Repository created.");
});

test("the repository overview displays its clone URL in the Code menu", async ({page}, testInfo) => {
  const name = `clone-${Date.now()}-${testInfo.workerIndex}`;
  await page.goto("/ui/create");
  await page.locator("#repository-name").fill(name);
  await page.getByRole("button", {name: "Create repository"}).click();
  await expect(page.locator("#form-status")).toContainText("Repository created.");
  await page.goto(`/ui/repos/${name}`);
  await page.locator(".code-menu summary").click();
  await expect(page.locator(".clone-field input")).toHaveValue(
    `${new URL(page.url()).origin}/git/${name}.git`,
  );
  await expect(page.getByRole("button", {name: "Copy clone URL"})).toBeVisible();
  await expect(page.locator(".readme-content")).toContainText(name);
  await expect(page.locator(".repository-contents")).toContainText("README.md");
  await expect(page.getByText("Files on main")).toHaveCount(0);
  await expect(page.locator("#tags")).toHaveCount(0);
  await expect(page.getByText("Recent activity")).toHaveCount(0);
  await page.goto(`/ui/repos/${name}/files/main`);
  await expect(page.locator(".tree-list")).toContainText("README.md");
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
  await expect(page.locator("#reference-choice")).toHaveValue("refs/heads/main");
  await expect(page.locator(".contents-commit")).toContainText("Document the project");
  await expect(page.locator(".tree-entry-time")).toHaveCount(2);
  await page.getByRole("button", {name: "Go to file"}).click();
  await page.getByRole("searchbox", {name: "Filter files"}).fill("README");
  await expect(page.locator(".tree-entry-link", {hasText: "README.md"})).toBeVisible();
  await expect(page.locator(".tree-entry-link", {hasText: "src"})).toBeHidden();
  await page.locator("#reference-choice").selectOption("refs/heads/main");
  await page.goto("/ui/repos/demo/files/main");
  await expect(page.locator(".tree-list")).toContainText("README.md");
  await expect(page.locator(".tree-list")).toContainText("src");
});

test("shows the supported repository navigation and pull requests", async ({page}) => {
  await page.route("**/api/repos/demo/pulls", async (route) => json(route, [
    {
      id: "pull-1", state: "open", source_ref: "refs/heads/feature",
      target_ref: "refs/heads/main", base_oid: "base", head_oid: "head", version: 1,
    },
  ]));
  await page.goto("/ui/repos/demo/pulls");
  await expect(page.locator(".repository-tabs")).toContainText("CodeIssuesPull requestsAudit");
  await expect(page.locator(".repository-tab.is-active")).toHaveText("Pull requests");
  await expect(page.locator(".pull-request-list")).toContainText("feature into main");
  await expect(page.locator(".pull-request-list")).toContainText("#pull-1");
  await expect(page.getByRole("link", {name: "New pull request"})).toHaveAttribute(
    "href", "/ui/repos/demo/pulls/new",
  );
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

test("shows pull request conversation and changed files tabs", async ({page}) => {
  await page.route("**/api/repos/demo/pulls/pull-1", async (route) => json(route, {
    id: "pull-1", state: "draft", source_ref: "refs/heads/feature",
    target_ref: "refs/heads/main", base_oid: "base", head_oid: "head", version: 1,
  }));
  await page.route("**/api/repos/demo/compare?*", async (route) => json(route, {
    diff: "@@ -1 +1 @@\n-old line\n+new line",
  }));
  await page.goto("/ui/repos/demo/pulls/pull-1");
  await expect(page.getByRole("heading", {name: "feature into main"})).toBeVisible();
  await expect(page.getByRole("button", {name: "Ready for review"})).toBeVisible();
  await page.getByRole("button", {name: "Files changed"}).click();
  await expect(page.locator(".diff-viewer")).toContainText("new line");
  await page.getByRole("button", {name: "Conversation"}).click();
  await expect(page.locator(".merge-box")).toBeVisible();
});

test("creates pull requests from branch selections without technical ID fields", async ({page}) => {
  const branches = [
    {name: "refs/heads/feature", oid: "b".repeat(40), algorithm: "sha1", version: 1},
    {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
  ];
  await page.route("**/api/repos/demo/branches", async (route) => json(route, branches));
  let submitted;
  await page.route("**/api/repos/demo/pulls", async (route) => {
    submitted = route.request().postDataJSON();
    await json(route, {...submitted, state: "draft", version: 1}, 201);
  });
  await page.route("**/api/repos/demo/pulls/*", async (route) => json(route, {
    id: submitted?.id || "created", state: "draft", source_ref: "refs/heads/feature",
    target_ref: "refs/heads/main", base_oid: "a".repeat(40), head_oid: "b".repeat(40), version: 1,
  }));
  await page.goto("/ui/repos/demo/pulls/new");
  await expect(page.getByLabel("Base")).toHaveValue("refs/heads/main");
  await expect(page.getByLabel("Compare")).toHaveValue("refs/heads/feature");
  await expect(page.getByLabel(/object ID|pull request ID/i)).toHaveCount(0);
  await page.getByRole("button", {name: "Create pull request"}).click();
  await page.waitForURL(/\/pulls\/[^/]+$/);
  expect(submitted.source_ref).toBe("refs/heads/feature");
  expect(submitted.target_ref).toBe("refs/heads/main");
  expect(submitted.base_oid).toBe("a".repeat(40));
  expect(submitted.head_oid).toBe("b".repeat(40));
});

test("compares references and toggles diff views", async ({page}) => {
  await page.route("**/api/repos/demo/branches", async (route) => json(route, [
    {name: "refs/heads/main", oid: "a".repeat(40), algorithm: "sha1", version: 1},
  ]));
  await page.route("**/api/repos/demo/tags", async (route) => json(route, [
    {name: "refs/tags/v1", oid: "b".repeat(40), algorithm: "sha1", version: 1},
  ]));
  await page.route("**/api/repos/demo/compare*", async (route) => json(route, {
    diff: "@@ -1 +1 @@\n-old line\n+new line",
  }));
  await page.goto("/ui/repos/demo/compare");
  await page.locator("#compare-base").selectOption("refs/heads/main");
  await page.locator("#compare-head").selectOption("refs/tags/v1");
  await page.getByRole("button", {name: "Compare"}).click();
  await expect(page.locator(".diff-viewer")).toContainText("new line");
  await page.getByRole("button", {name: "Show split view"}).click();
  await expect(page.locator(".split-diff")).toBeVisible();
  await expect(page.locator(".split-diff .diff-added")).toContainText("new line");
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
