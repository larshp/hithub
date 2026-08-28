import {spawn} from "node:child_process";

const port = 3500;
const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {...process.env, HITHUB_PORT: String(port)},
  stdio: "inherit",
});

try {
  let response;
  for (let attempt = 0; attempt < 50; attempt += 1) {
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
      || !appSource.includes("showCommitHistory")
      || !appSource.includes("commit-list")
      || !appSource.includes("showCommitDetail")
      || !appSource.includes("commit-message")
      || !appSource.includes("textContent")
      || appSource.includes("innerHTML")) {
    throw new Error("UI smoke test could not load dashboard behavior");
  }
  const route = await fetch(`http://127.0.0.1:${port}/ui/repos/demo`);
  if (!route.ok || !(await route.text()).includes("id=\"main-content\"")) {
    throw new Error("UI smoke test could not load the repository route shell");
  }
  console.log("UI layout smoke test passed");
} finally {
  child.kill("SIGTERM");
}
