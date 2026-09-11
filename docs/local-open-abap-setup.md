# Local open-abap setup

## Prerequisites

Use Node.js 22, the version used by the repository CI jobs, and a Git client
available on `PATH`. The transpiler downloads the pinned open-abap-core and
express-icf-shim source libraries during a build, so the first build needs
network access to GitHub.

## Install and verify

From a clean checkout, install the locked dependency tree and run the source
checks:

```sh
npm ci
npm run lint
npm run unit
npm run schema
npm run fixtures
npm run smoke
```

`npm ci` honors the repository's `ignore-scripts` setting. It does not create
browser binaries or a production database. Generated transpiled files live
under `output/` and are intentionally ignored by Git.

For the full local verification set, also run the REST, security, resilience,
native Git, load/soak, and browser checks:

```sh
npm run contract
npm run security
npm run limits
npm run logging
npm run metrics
npm run readiness
npm run timeout
npm run backpressure
npm run restore-verify
npm run load-soak
npm run native-fsck
npm run native-race
npm run e2e:install
npm run e2e
```

The browser install is needed once per machine. In an offline environment,
populate the npm and open-abap caches first; do not replace the pinned
libraries with unreviewed local copies.

## Run the local service

Transpile the ABAP sources, then start the Express ICF shim:

```sh
npm run transpile
HITHUB_PORT=3000 npm start
```

The service listens on `127.0.0.1` and exposes `/live`, `/ready`, `/health`,
`/metrics`, the REST API under `/api`, and Git Smart HTTP routes under
`/{repository}.git`. Local development has no built-in user directory and
uses the fixed local actor unless an approved test adapter supplies another
context.

Useful development settings are documented in the [deployment topology
guide](deployment-topology.md), including CORS, cookie-authenticated CSRF,
request limits, timeouts and single-process limitations. To seed a temporary
empty repository or fixture repository for native Git checks, use the same
environment variables as the test scripts:

```sh
HITHUB_PORT=3000 HITHUB_EMPTY_REPOSITORY=demo npm start
HITHUB_PORT=3000 HITHUB_FIXTURE_REPOSITORY=fixture npm start
```

Do not use those seed variables for production data. The local SQLite adapter
is a development/test runtime; SAP deployments use the DDIC and ICF
installation procedures instead.

## Troubleshooting

- If transpilation cannot clone an open-abap library, verify GitHub access and
  rerun `npm run transpile`.
- If a port is busy, choose another `HITHUB_PORT` and update the client URL.
- If generated imports are missing, rerun `npm run transpile` from the
  repository root.
- If browser tests fail before starting, run `npm run e2e:install` and confirm
  the Playwright browser dependencies are available on the host.
