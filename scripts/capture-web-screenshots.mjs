// Photographs the preview build.
//
// The screenshots are deployed next to the preview and compared with the ones
// taken from main, so a reviewer can see what a pull request did to the user
// interface without opening every page. That comparison is only worth reading
// if the pages are identical whenever the application is: the preview seeds the
// same content on every boot, its clock is pinned, and the browser clock is
// pinned here to the same instant so relative timestamps do not drift.
import express from "express";
import {mkdir, mkdtemp, readdir, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import {chromium} from "@playwright/test";
import {PREVIEW_INSTANT} from "../web/preview-instant.mjs";

const build = resolve(process.cwd(), "build");
const screenshots = resolve(build, "screenshots");
const viewport = {width: 1440, height: 960};
const port = Number(process.env.HITHUB_PREVIEW_PORT || 4173);
const repository = "hithub";

// One page per part of the application worth reviewing. The name becomes the
// file name and the caption, and is what the visual diff compares across
// deployments, so it has to stay stable even when the seeded content moves.
// Issues and pull requests are numbered by the server, so the pages that show
// one are asked for rather than assumed.
function pagesFor({pull, issue}) {
  return [
    {name: "repositories", path: "/", description: "Repository dashboard"},
    {name: "repository", path: `/ui/repos/${repository}`,
      description: "Repository overview with the rendered README"},
    {name: "files", path: `/ui/repos/${repository}/files/main`,
      description: "File browser on the default branch"},
    {name: "file", path: `/ui/repos/${repository}/blob/main/README.md`,
      description: "Single file with its contents"},
    {name: "commits", path: `/ui/repos/${repository}/commits/main`,
      description: "Commit history"},
    {name: "issues", path: `/ui/repos/${repository}/issues`,
      description: "Issue list"},
    {name: "issue", path: `/ui/repos/${repository}/issues/${issue}`,
      description: "Issue with labels and comments"},
    {name: "pulls", path: `/ui/repos/${repository}/pulls`,
      description: "Pull request list"},
    {name: "pull-request", path: `/ui/repos/${repository}/pulls/${pull}`,
      description: "Pull request conversation"},
    {name: "new-repository", path: "/ui/create",
      description: "Repository creation form"},
  ];
}

let pages = [];

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

async function serveBuild() {
  const app = express();
  app.use(express.static(build));
  return new Promise((fulfil) => {
    const server = app.listen(port, "127.0.0.1", () => fulfil(server));
  });
}

async function settle(page) {
  // Every page renders a placeholder while it fetches. Waiting for the
  // placeholders to go is what keeps the screenshots comparable; waiting for
  // the network does not, because the service worker answers instantly and the
  // rendering happens afterwards.
  await page.waitForFunction(() => {
    const main = document.querySelector("#main-content");
    return main !== null && !/Loading/i.test(main.textContent || "");
  }, undefined, {timeout: 30_000});
  await page.evaluate(() => document.fonts.ready.then(() => true));

  // A page that answered with "could not be loaded" still renders, and would be
  // photographed and deployed as if it were the application working. The point
  // of the preview is that it works, so treat it as a failed build instead.
  const failure = await page.evaluate(() => {
    const text = document.querySelector("#main-content")?.textContent || "";
    const match = /[^.]*could not be [a-z]+\./.exec(text);
    return match === null ? "" : match[0].trim();
  });
  if (failure !== "") {
    throw new Error(`${page.url()} did not render: ${failure}`);
  }
}

async function writeIndex() {
  const files = (await readdir(screenshots, {withFileTypes: true}))
    .filter((entry) => entry.isFile() && entry.name.endsWith(".png"))
    .map((entry) => entry.name)
    .sort((left, right) => left.localeCompare(right));
  const described = new Map(pages.map((page) => [`${page.name}.png`, page]));
  const cards = files.map((file) => {
    const page = described.get(file);
    const label = escapeHtml(file.replace(/\.png$/, ""));
    return `        <figure>
          <a href="${escapeHtml(file)}"><img src="${escapeHtml(file)}" alt="${label}" width="${viewport.width}" height="${viewport.height}" loading="lazy"></a>
          <figcaption><strong>${label}</strong><span>${escapeHtml(page?.description || "")}</span><code>${escapeHtml(page?.path || "")}</code></figcaption>
        </figure>`;
  }).join("\n");

  await writeFile(resolve(screenshots, "index.html"), `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>HitHub preview screenshots</title>
    <style>
      :root { color-scheme: light; font-family: system-ui, sans-serif; color: #172b3f; background: #eef3f8; }
      body { margin: 0; padding: 2rem; }
      h1 { margin: 0 0 .35rem; }
      .intro { margin: 0 0 1.5rem; color: #52677c; }
      main { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1.25rem; }
      figure { margin: 0; }
      a { display: block; }
      img { display: block; width: 100%; height: auto; border: 1px solid #aebfd2; background: #fff; }
      figcaption { display: flex; flex-direction: column; gap: .2rem; padding-top: .45rem; }
      figcaption strong { font: 700 1rem ui-monospace, monospace; }
      figcaption span { color: #52677c; }
      figcaption code { color: #6d7f90; }
      @media (max-width: 700px) { body { padding: 1rem; } }
    </style>
  </head>
  <body>
    <h1>HitHub preview screenshots</h1>
    <p class="intro">${files.length} page${files.length === 1 ? "" : "s"} of the preview deployment, captured at ${viewport.width}&times;${viewport.height}.</p>
    <main>
${cards}
    </main>
  </body>
</html>
`, "utf8");
}

await rm(screenshots, {recursive: true, force: true});
await mkdir(screenshots, {recursive: true});

const server = await serveBuild();
// A service worker needs somewhere to live: Chromium refuses to register one
// for a browser context that has no profile on disk.
const profile = await mkdtemp(join(tmpdir(), "hithub-preview-"));
const context = await chromium.launchPersistentContext(profile, {
  headless: true,
  viewport,
});
try {
  const page = context.pages()[0] || await context.newPage();
  await page.clock.setFixedTime(new Date(PREVIEW_INSTANT));

  // The first load installs the service worker and reloads into the
  // application. Everything after it is an ordinary navigation.
  await page.goto(`http://127.0.0.1:${port}/`, {waitUntil: "load"});
  await page.waitForSelector("#main-content", {timeout: 60_000});
  await settle(page);

  const read = (route) => page.evaluate(
    (target) => fetch(target).then((response) => response.json()), route);
  const [pulls, issues] = await Promise.all([
    read(`/api/repos/${repository}/pulls`),
    read(`/api/repos/${repository}/issues`),
  ]);
  const byNumber = (left, right) => Number(left.id) - Number(right.id);
  pages = pagesFor({
    pull: [...pulls].sort(byNumber)[0].id,
    issue: [...issues].sort(byNumber)[0].id,
  });

  for (const {name, path} of pages) {
    await page.goto(`http://127.0.0.1:${port}${path}`, {waitUntil: "load"});
    await settle(page);
    await page.screenshot({path: resolve(screenshots, `${name}.png`)});
    console.log(`Captured ${name} from ${path}`);
  }
} finally {
  await context.close();
  await rm(profile, {recursive: true, force: true});
  server.close();
}

await writeIndex();
console.log(`Wrote ${resolve(screenshots, "index.html")}`);
