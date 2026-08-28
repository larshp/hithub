# Changelog

All notable HitHub changes are recorded here. The project follows the
unversioned API policy in [`docs/api-compatibility.md`](docs/api-compatibility.md);
the OpenAPI contract revision is tracked separately in
[`docs/openapi.yaml`](docs/openapi.yaml).

## [Unreleased]

### Added

- Dual SAP ICF and local open-abap runtime support with ABAP-owned behavior.
- Git Smart HTTP v0/v1 clone, fetch, push, branch, tag, pack and delta flows,
  plus protocol-v2 advertisement, `ls-refs`, and fetch support.
- Repository, reference, object, pull-request, review, issue, comment, label,
  activity and audit workflows through REST and the web UI.
- Safe compare-and-swap reference updates, repository locking, quarantine
  promotion, merge strategies, idempotent merge results, and race checks.
- Structured logs, request correlation IDs, metrics, health/readiness probes,
  quotas, rate limits, timeouts, back-pressure, reachability GC, grace periods,
  and dry-run GC reporting.
- SAP ICF, DDIC, local setup, administrator, backup/restore, upgrade,
  capability, and API compatibility documentation.

### Security

- Added CSP, explicit CORS, cookie-authenticated CSRF checks, path/ref/object
  validation, bounded pack/delta processing, sanitized operational telemetry,
  and deployment-boundary guidance.
- Added injected-failure coverage for single-ref and batch quarantine
  promotion, preserving refs and transaction cleanup on failure.

### Verification

- ABAP lint, transpilation, unit, schema, fixture, REST contract, security,
  limits, logging, metrics, readiness, timeout, back-pressure, restore,
  load/soak, native Git fsck, native merge, and race suites pass locally.
- The current local native Git baseline is Git 2.43.0. Older native Git and
  external SAP deployment runs remain environment-dependent release work.

### Compatibility and limitations

- Supported deployment floor: SAP NetWeaver AS ABAP 7.52 SP04 or later, with
  shared database and enqueue services for scale-out.
- Initial native Git target: 2.30 and later; representative matrix: 2.30,
  2.39, and 2.43. Initial abapGit target: v1.131.0 through v1.134.0.
- The MVP has no built-in user directory, repository roles, SSH transport,
  Git LFS, Dumb HTTP, packages, Pages, wikis, projects, organizations,
  federation, or CI runners.
- Authentication, TLS, coarse service authorization, cluster-wide limits,
  backup tooling, and SAP application-server hardening remain deployment
  responsibilities.
