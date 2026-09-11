# Preview deployments

Every pull request gets a running copy of HitHub to click through, and a
screenshot comparison against `main`. Both are published to
[larshp/hithub-preview-deployments](https://github.com/larshp/hithub-preview-deployments)
by `.github/workflows/preview-deploy.yml` and served from GitHub Pages:

| What | Where |
| --- | --- |
| The application | `https://larshp.github.io/hithub-preview-deployments/pr-<number>/` |
| Screenshots | `.../pr-<number>/screenshots/` |
| Visual diffs against main | `.../pr-<number>/visual-diffs/` |
| The same three for the default branch | `.../main/...` |

A push to `main` deploys into `main/`, which is the baseline every pull request
is compared against. Closing a pull request removes its directory.

## How an HTTP application is served from a file host

GitHub Pages hands out files; HitHub answers requests. The preview bridges the
two with a service worker.

`web/preview-worker.mjs` is to the browser what `server/index.mjs` is to Node.
It strips the mount path - `/hithub-preview-deployments/pr-42/`, where an
installed service has its SICF node - forwards the request into
`ZCL_HITHUB_HTTP` through the same `CL_EXPRESS_ICF_SHIM` the local server uses,
and turns the answer into an HTTP response. `webpack.config.cjs` bundles the
transpiled application, the browser assets from `src/frontend` and a SQLite
engine compiled to JavaScript into that worker.

What a visitor gets is therefore the real thing: the unmodified frontend, real
URLs that survive a reload, and a database that answers real queries. It runs
entirely in their browser, so nothing they do reaches anyone else, and a
[reset](#resetting-a-preview) puts it back.

`build/index.html` is the only page GitHub Pages itself serves. It installs the
worker and steps aside; from then on the worker answers that address. A deep
link opened before the worker exists misses, so Pages serves the `404.html` at
the root of the deployment repository, which remembers the address, sends the
visitor to the preview directory and lets the worker take it from there.

### What the preview is not

- **Not a git remote.** The repository pages show a clone URL, but a git client
  does not run service workers; `git clone` against a preview will not work.
- **Not shared.** The database lives in the visitor's browser. Two people
  looking at the same preview do not see each other's edits.
- **Not persistent.** Browser storage keeps it across reloads and across the
  worker being shut down, and clearing site data starts over.

## The seeded content

An empty HitHub shows an empty dashboard, so `web/preview-seed.mjs` fills one in
on the first boot: a repository with a README built up over several commits, a
branch with an open pull request against it - reviewed and commented - three
issues with labels and comments, and a second repository.

It builds all of that through the REST API rather than through SQL, which keeps
it honest: the seed exercises the code the preview exists to show. That also
bounds it. The contents API rewrites existing files rather than creating them,
so the history is a series of edits to the README that the initial commit
writes.

## Why the clocks are pinned

The visual diff is only worth reading if two deployments of the same code
produce the same pixels. The seed runs on every boot, so its timestamps would
otherwise be the wall clock of the workflow run, and every page showing a
relative time would report a difference that is only the clock.

`web/preview-runtime.mjs` pins the ABAP runtime to the instant in
`web/preview-instant.mjs`, and `scripts/capture-web-screenshots.mjs` pins the
browser to the same one. A preview therefore always says a repository was
created on the same date.

## Building it locally

```sh
npm run web:preview      # transpile, then bundle the worker into build/
npm run web:screenshots  # photograph the pages in build/screenshots
npm run web:diff         # compare them with deployment/main/screenshots
npm run web:build        # all three, which is what the workflow runs
```

`npm run web:diff` expects the deployed `main` screenshots in
`deployment/main/screenshots`; the workflow checks the deployment repository out
there. Without them every page is reported as added, which is also what the
first deployment of a new preview directory looks like.

To open the build, serve `build/` over HTTP - a service worker will not register
from a `file://` URL:

```sh
npx http-server build -p 4173   # or any static file server
```

### Resetting a preview

`<preview>/__preview/reset` throws the database away, seeds it again and
returns to the start page. The preview's error page links to it.

## One-time setup

1. Create the deployment repository and enable GitHub Pages on its default
   branch.
2. Add a deploy key with write access to it.
3. Put the private half of that key in the `DEPLOY` secret of this repository.

Pull requests from forks are skipped: the deploy key must not be exposed to a
workflow the fork can change.

The deployment repository accumulates a few megabytes per preview, since each
one carries its own copy of the bundled runtime. Removing closed pull requests
keeps the working tree small but not the history; if it ever becomes a problem,
the deployment repository can be recreated - nothing depends on its history.
