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
- `GET /api/repos/{repo}/compare` returns a three-dot comparison between two
  references with per-file unified diffs, add/delete counts, and a change
  summary; the Compare page and the pull-request "Files changed" tab now read
  it from the real backend instead of a test double.
- `GET`/`POST /api/repos/{repo}/pulls/{pull}/reviews` and `.../comments`, plus
  `GET`/`POST`/`DELETE` for issue labels and assignees, connect the existing
  review, comment, label and assignee domain classes to REST. The pull-request
  sidebar lists real reviewers and the issue sidebar edits labels and
  assignees in place, replacing the previous static placeholders.

### Fixed

- The Code menu advertised `/git/{repo}.git`, which the Git router never
  served; it now shows `/{repo}.git`, and UI tests fetch the advertised URL to
  keep it reachable.

### Documentation

- Corrected the documented merge route from `PUT /api/repos/{repo}/pulls/
  {pull}` to the implemented `PUT /api/repos/{repo}/pulls/{pull}/merge`, and
  added the missing contents and comparison routes to the OpenAPI contract.
  The server behavior is unchanged; only the contract was wrong.

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
