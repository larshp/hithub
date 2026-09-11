# Administrator configuration

## Deployment boundary

Protect the complete HitHub service at SAP ICF or a trusted upstream gateway.
The MVP has no user directory or repository-level authorization: every
authenticated caller receives the same application capabilities. Require
HTTPS, authenticate `/health`, `/api/*`, and every `*.git/*` route, and strip
untrusted actor headers before forwarding requests. See the [SAP ICF
installation guide](sap-icf-access.md) and [gateway policy](upstream-gateway-access.md).

For SAP scale-out, use shared database persistence and the SAP enqueue service
for every application server. Enforce equivalent connection, body, timeout,
rate and concurrency limits at Web Dispatcher or the gateway; the local
in-memory controls below are single-process controls and are not a shared
cluster limiter.

## Local runtime settings

The Node/open-abap adapter reads these environment variables at process start:

| Variable | Default | Purpose |
| --- | --- | --- |
| `HITHUB_PORT` | `3000` | Loopback HTTP port for local development. |
| `HITHUB_CORS_ORIGIN` | disabled | Comma-separated exact CORS origins; `*` is allowed only for controlled development. |
| `HITHUB_COOKIE_AUTH` | `false` | Enables CSRF checks for cookie-authenticated mutations. |
| `HITHUB_CSRF_COOKIE` | `hithub_csrf` | Cookie name used by the CSRF check. |
| `HITHUB_BODY_LIMIT` | `64mb` | Maximum parsed HTTP request body. |
| `HITHUB_OPERATION_TIMEOUT_MS` | `120000` | Node HTTP operation timeout in milliseconds. |
| `HITHUB_HTTP_CONCURRENCY` | `64` | Maximum in-flight local HTTP requests. |
| `HITHUB_GIT_CONCURRENCY` | `8` | Maximum in-flight local Git operations. |
| `HITHUB_RATE_LIMIT` | `300` | Requests per client and rate window; set to `0` to disable locally. |
| `HITHUB_RATE_WINDOW_MS` | `60000` | Local rate-limit window in milliseconds. |

`HITHUB_EMPTY_REPOSITORY` and `HITHUB_FIXTURE_REPOSITORY` are test-only seed
switches. Never set them in a production process. SAP deployments configure
the equivalent values in ICF, Web Dispatcher, and the SAP application
runtime; they do not use the Node environment variables.

The initial object, pack, repository, delta-depth, concurrency and timeout
targets are listed in the [resource limits](resource-limits.md) and
[operational targets](operational-targets.md) documents. Lower a limit when
the SAP memory or request-time budget requires it. Increasing a safety ceiling
requires a capacity review, a load test, and an updated deployment record.

## Recommended local configuration

Use an explicit origin and cookie-authenticated CSRF check when exercising a
browser against a non-loopback proxy:

```sh
HITHUB_PORT=3000 \
HITHUB_CORS_ORIGIN=https://console.example.test \
HITHUB_COOKIE_AUTH=true \
HITHUB_BODY_LIMIT=64mb \
HITHUB_HTTP_CONCURRENCY=64 \
HITHUB_GIT_CONCURRENCY=8 \
npm start
```

Keep the default loopback bind for development. Put TLS termination,
authentication, and rate limiting in front of any externally reachable
instance.

## Operations

- Monitor `/live` for process liveness and `/ready` for database readiness.
- Scrape `/metrics` without exposing request bodies, credentials, pack data or
  repository content. Retain structured logs with their request correlation
  IDs according to the deployment audit policy.
- Run consistent database/object-store backups using the [backup
  runbook](backup-runbook.md), and rehearse isolated restores using the
  [restore runbook](restore-runbook.md).
- Schedule reachability-based garbage collection with the configured grace
  period. Review its dry-run report before deleting unreachable objects, and
  keep active quarantine roots protected.
- During an upgrade or DDIC change, follow the [schema-change
  runbook](ddic-schema-runbook.md) and retain the pre-change backup.

## Configuration change validation

After changing limits, access policy, or the SAP transport, verify readiness
and run the relevant local or deployment-boundary tests:

```sh
npm run readiness
npm run security
npm run limits
npm run logging
npm run metrics
npm run timeout
npm run backpressure
npm run load-soak
```

For SAP, repeat the authenticated/unauthenticated ICF checks, binary Git
discovery check, clone/push check, shared-lock check, and log-redaction review
in a non-production system before promotion.
