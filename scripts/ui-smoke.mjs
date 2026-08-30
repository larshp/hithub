import {spawn} from "node:child_process";
import {chromium} from "playwright";

const port = 3500;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});
let browser;

try {
  let response;
  for (let attempt = 0; attempt < 300; attempt += 1) {
    try {
      response = await fetch(`http://127.0.0.1:${port}/`);
      if (response.ok) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  const html = response ? await response.text() : "";
  if (!response?.ok || !html.includes("Skip to main content")
      || !html.includes('id="main-content"') || !html.includes("HitHub")) {
    throw new Error("UI smoke test received an invalid global layout");
  }
  const css = await fetch(`http://127.0.0.1:${port}/styles.css`);
  if (!css.ok) throw new Error("UI smoke test could not load styles.css");
  const app = await fetch(`http://127.0.0.1:${port}/app.js`);
  const appSource = await app.text();
  if (!app.ok || !appSource.includes("/api/repos")
      || !appSource.includes("repositoryCard")
      || !appSource.includes("showCreateForm")
      || !appSource.includes("showRepositoryOverview")
      || !appSource.includes("renderMarkdownSafe")
      || !appSource.includes("reference-choice")
      || !appSource.includes("showTreeBrowser")
      || !appSource.includes("renderTreeEntry")
      || !appSource.includes("showBlobViewer")
      || !appSource.includes("blob-viewer")
      || !appSource.includes("Download raw")
      || !appSource.includes("download")
      || !appSource.includes("renderSourceSafe")
      || !appSource.includes("token-keyword")
      || !appSource.includes("blob-fallback")
      || !appSource.includes("content-length")
      || !appSource.includes("showCompareView")
      || !appSource.includes("compare-base")
      || !appSource.includes("renderUnifiedDiffSafe")
      || !appSource.includes("diff-added")
      || !appSource.includes("renderSplitDiffSafe")
      || !appSource.includes("Show split view")
      || !appSource.includes("Merge pull request")
      || !appSource.includes("merge-button")
      || !appSource.includes("showCommitHistory")
      || !appSource.includes("commit-list")
      || !appSource.includes("showCommitDetail")
      || !appSource.includes("commit-message")
      || !appSource.includes("showPullRequest")
      || !appSource.includes("Ready for review")
      || !appSource.includes("showCreatePullRequest")
      || !appSource.includes("showIssues")
      || !appSource.includes("showIssue")
      || !appSource.includes("showCreateIssue")
      || !appSource.includes("Close issue")
      || !appSource.includes("Leave a comment")
      || !appSource.includes("showAudit")
      || !appSource.includes("Repository audit")
      || !appSource.includes("/audit")
      || !appSource.includes("Merge pull request")
      || !appSource.includes("Merge status:")
      || !appSource.includes("conflicting files")
      || !appSource.includes("textContent")
      || appSource.includes("innerHTML")) {
    throw new Error("UI smoke test could not load dashboard behavior");
  }
  const route = await fetch(`http://127.0.0.1:${port}/ui/repos/demo`);
  if (!route.ok || !(await route.text()).includes("id=\"main-content\"")) {
    throw new Error("UI smoke test could not load the repository route shell");
  }
  const created = await fetch(`http://127.0.0.1:${port}/api/repos`, {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "ui-issue-repository"}),
  });
  if (created.status !== 201) throw new Error("UI issue test repository creation failed");
  browser = await chromium.launch({headless: true});
  const page = await browser.newPage();
  await page.goto(
    `http://127.0.0.1:${port}/ui/repos/ui-issue-repository/issues/new`,
    {waitUntil: "networkidle"},
  );
  await page.getByLabel("Title").fill("UI issue");
  await page.getByLabel("Description").fill("Initial description");
  await page.getByRole("button", {name: "Create issue"}).click();
  await page.waitForURL(/\/issues\/[^/]+$/);
  await page.getByRole("button", {name: "Close issue"}).click();
  await page.getByLabel("State: closed").waitFor();
  await page.getByRole("button", {name: "Reopen issue"}).click();
  await page.getByLabel("State: open").waitFor();
  await page.getByRole("button", {name: "Edit"}).click();
  await page.getByLabel("Edit title").fill("Updated UI issue");
  await page.getByLabel("Edit description").fill("Updated description");
  await page.getByRole("button", {name: "Save changes"}).click();
  await page.getByRole("heading", {name: "Updated UI issue"}).waitFor();
  const commentForm = page.locator(".comment-composer");
  await commentForm.locator("textarea").fill("A UI comment");
  await commentForm.getByRole("button", {name: "Comment"}).click();
  await page.getByText("A UI comment").waitFor();
  await page.goto(
    `http://127.0.0.1:${port}/ui/repos/ui-issue-repository/issues`,
    {waitUntil: "networkidle"},
  );
  await page.getByRole("link", {name: "Updated UI issue"}).waitFor();
  console.log("UI issue workflow passed");
  console.log("UI layout smoke test passed");
} finally {
  await browser?.close();
  child.kill("SIGTERM");
}
