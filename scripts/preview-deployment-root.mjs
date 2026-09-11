// Writes the two pages that sit at the root of the preview deployment
// repository:
//
//   index.html   lists the previews that are currently deployed
//   404.html     sends a preview URL to the page that installs the worker
//
//   node scripts/preview-deployment-root.mjs <deployment directory>
//
// GitHub Pages only serves files, so a preview URL below /pr-<number>/ is a
// miss until the service worker is installed in the visitor's browser. Pages
// answers a miss with the 404 page at the root of the site, which is why the
// deep link bootstrap lives there rather than in the preview directory.
import {readdir, writeFile} from "node:fs/promises";
import {resolve} from "node:path";

const deployment = resolve(process.argv[2] || "deployment");
// The directory names .github/workflows/preview-deploy.yml deploys into.
const PREVIEW_DIRECTORY = /^(?:pr-\d+|main|preview)$/;

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function order(left, right) {
  // main first, then the open pull requests by descending number.
  if (left === right) return 0;
  if (left === "main") return -1;
  if (right === "main") return 1;
  const numbers = [left, right].map((name) => Number(name.replace("pr-", "")));
  if (Number.isFinite(numbers[0]) && Number.isFinite(numbers[1])) {
    return numbers[1] - numbers[0];
  }
  return left.localeCompare(right);
}

const previews = (await readdir(deployment, {withFileTypes: true}))
  .filter((entry) => entry.isDirectory() && PREVIEW_DIRECTORY.test(entry.name))
  .map((entry) => entry.name)
  .sort(order);

const rows = previews.map((name) => {
  const label = escapeHtml(name);
  const description = name === "main"
    ? "The default branch"
    : `Pull request #${name.replace("pr-", "")}`;
  return `        <tr>
          <th scope="row"><a href="${label}/">${label}</a></th>
          <td>${description}</td>
          <td><a href="${label}/screenshots/">Screenshots</a></td>
          <td><a href="${label}/visual-diffs/">Visual diffs</a></td>
        </tr>`;
}).join("\n");

await writeFile(resolve(deployment, "index.html"), `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>HitHub preview deployments</title>
    <style>
      :root { color-scheme: light; font-family: system-ui, sans-serif; color: #172b3f; background: #eef3f8; }
      body { margin: 0; padding: 2rem; }
      h1 { margin: 0 0 .35rem; }
      p { margin: 0 0 1.25rem; max-width: 46rem; color: #52677c; }
      table { border-collapse: collapse; background: #fff; border: 1px solid #b8c9dc; border-radius: 6px; }
      th, td { padding: .6rem .9rem; text-align: left; border-bottom: 1px solid #dce8f3; }
      tbody tr:last-child th, tbody tr:last-child td { border-bottom: 0; }
      th[scope="row"] { font: 700 1rem ui-monospace, monospace; }
      .empty { padding: 1rem; border: 1px solid #b8c9dc; border-radius: 6px; background: #fff; }
      @media (max-width: 700px) { body { padding: 1rem; } table, thead, tbody, tr, th, td { display: block; } td { border: 0; padding-top: 0; } }
    </style>
  </head>
  <body>
    <h1>HitHub preview deployments</h1>
    <p>
      Every deployment here runs the complete HitHub server in your browser:
      the ABAP application is transpiled to JavaScript and hosted by a service
      worker, with its database compiled in. Nothing is sent anywhere, and
      anything you change is yours alone until you clear the site data.
      Deployed by
      <a href="https://github.com/larshp/hithub">larshp/hithub</a>.
    </p>
${previews.length === 0 ? '    <p class="empty">No previews are deployed.</p>' : `    <table>
      <thead>
        <tr><th scope="col">Preview</th><th scope="col">Source</th><th scope="col" colspan="2">Reports</th></tr>
      </thead>
      <tbody>
${rows}
      </tbody>
    </table>`}
  </body>
</html>
`, "utf8");

await writeFile(resolve(deployment, "404.html"), `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="dark">
    <title>HitHub preview</title>
    <style>
      body { margin: 0; min-height: 100vh; display: grid; place-items: center; font: 16px/1.5 system-ui, sans-serif; color: #e6edf3; background: #0d1117; }
      main { max-width: 34rem; padding: 2rem; }
      h1 { margin: 0 0 .5rem; font-size: 1.4rem; }
      p { margin: 0 0 .75rem; color: #9198a1; }
      a { color: #4493f8; }
    </style>
  </head>
  <body>
    <main>
      <h1 id="heading">Opening the preview</h1>
      <p id="detail">One moment.</p>
    </main>
    <script>
      // A preview URL is a real URL inside the application, and the service
      // worker that answers it only exists once the preview has been opened
      // once in this browser. Remember where the visitor wanted to go, send
      // them to the preview directory, and let its page install the worker and
      // continue.
      (() => {
        const match = location.pathname.match(/^(.*?\\/(?:pr-\\d+|main|preview)\\/)(.+)$/);
        if (match === null) {
          document.querySelector("#heading").textContent = "Not found";
          document.querySelector("#detail").innerHTML =
            'There is no preview at this address. <a href="/">See the '
            + 'deployed previews</a>.';
          return;
        }
        try {
          sessionStorage.setItem("hithub-preview-target",
            location.pathname + location.search + location.hash);
        } catch (_error) {
          // Without storage the visitor lands on the preview start page
          // instead of the page they asked for.
        }
        location.replace(match[1]);
      })();
    </script>
  </body>
</html>
`, "utf8");

// Pages runs Jekyll over a site unless it is told not to, which costs build
// time and hides anything whose name begins with an underscore.
await writeFile(resolve(deployment, ".nojekyll"), "", "utf8");

console.log(`Wrote the deployment root for ${previews.length} preview(s): `
  + `${previews.join(", ") || "none"}`);
