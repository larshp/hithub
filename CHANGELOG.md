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
- The commits page is rebuilt to match the shape of a hosted Git service:
  commits are grouped under a dated heading on a timeline rail, each row shows
  the subject line with an expander for the message body, the author name and a
  relative time, and a trailing short commit id with copy and
  "browse the repository at this commit" actions. The branch/tag switcher from
  the Code page is reused at the top, and the raw committer identity no longer
  leaks into the row.
- Browsing file contents now accepts a plain commit id, and resolves annotated
  tags by peeling them to their commit, so the commits page can link each row
  at its own tree and `refs/tags/*` browsing works for annotated tags.
- Text files can be edited in the browser. The blob page shows an "Edit this
  file" button on branches, and committing rewrites every tree between the
  repository root and the file, writes a commit whose parent is the previous
  head, and advances the branch — all in one transaction under the repository
  lock. `PUT /api/repos/{repo}/contents/{path}` exposes the same operation;
  `expected_head_oid` makes a write fail with `409` rather than discard commits
  that landed while the file was open. Tags and raw commit references stay
  read-only, and an edit that changes nothing is rejected instead of producing
  an empty commit.
- The repository Code page replaces the branch/tag `<select>` with a search
  dropdown: a filter over branches and tags on separate tabs, a check mark on
  the current reference, a `default` badge, keyboard navigation, and a
  "Create branch <name> from <ref>" row that posts to the branch API and opens
  the new branch. The branch and tag counters open the dropdown on their tab.

### Changed

- **Breaking:** issues and pull requests are identified by a sequential,
  human-readable number (`#1`, `#2`, …) instead of a client-supplied opaque
  identifier. Both draw from **one sequence per repository**, so a repository
  never has both an issue #5 and a pull request #5. `POST` to
  `/api/repos/{repo}/issues` and `/api/repos/{repo}/pulls` no longer accepts an
  `id` field — the server assigns the number and returns it in the body and the
  `Location` header — and both lists are ordered by descending number so `#10`
  sorts above `#9`. Send `Idempotency-Key` to make a retried create replay the
  original record instead of consuming another number. Issues and pull requests
  created before this change keep their existing identifiers; they take no part
  in the sequence, and new numbers skip any that are already taken.

### Fixed

- The Code menu advertised `/git/{repo}.git`, which the Git router never
  served; it now shows `/{repo}.git`, and UI tests fetch the advertised URL to
  keep it reachable.
- Server-generated commits carried the Unix epoch as their author date, so the
  initial commit and every merge commit were dated 1970. They now carry the
  time they were made, which also stops the commits page from filing them under
  an undated heading.
- The browser test suite gated readiness on `/health`, which answers from a
  static branch that never touches the REST dispatch or the database. Tests
  therefore started against a server whose code paths were still loading, and
  the heaviest ones intermittently exceeded their timeout. The suite now waits
  for a REST route and warms the paths it exercises before the first test.

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
