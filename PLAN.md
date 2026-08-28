# HitHub implementation plan

## 1. Product goal

Build a self-hosted Git collaboration server whose application and Git-domain logic are written in ABAP. It should run in an SAP system through ICF and run locally on Node.js by transpiling the same ABAP with open-abap.

The first production-worthy release should provide:

- repository creation and administration without a built-in user directory;
- clone, fetch and push over Git Smart HTTP;
- repository, branch, tag, commit, tree, blob and diff browsing;
- pull requests with comments, reviews, mergeability checks and merging;
- issues and repository discussions through comments;
- a JSON REST API for the same core workflows;
- a responsive web frontend;
- deterministic automated tests that run locally without an SAP system.

This is not intended to reproduce every GitHub product. Built-in user setup, collaborators, invitations and repository roles are out of scope: the hosting runtime supplies any required authentication, and every admitted caller has the same HitHub capabilities. Packages, Pages, wikis, projects, Sponsors, organizations, federation, Git LFS and SSH transport are permanent non-goals. Actions/CI runners remain a possible follow-up feature unless a concrete use case promotes them.

## 2. Guiding decisions

1. **ABAP owns behavior.** Repository rules, Git object handling, pull-request state transitions and REST contracts live in ABAP. Node.js only adapts Express requests, persistence and process lifecycle for local open-abap execution.
2. **Hexagonal boundaries.** Core services depend on interfaces for persistence, locking, hashing, compression, time, request actor and HTTP. SAP and Node.js implementations sit outside the domain.
3. **Git compatibility before feature breadth.** Build and test the object database, pack files and wire protocol before pull requests or UI workflows.
4. **Smart HTTP v0/v1 first.** Implement the widely supported stateless `upload-pack` and `receive-pack` flow first. Add protocol v2 after the core clone/fetch/push matrix is stable. Do not implement Dumb HTTP.
5. **SHA-1 initially, algorithm-aware internally.** Git SHA-1 object IDs are the first interoperable target. Avoid fixed 40-character assumptions in public interfaces so SHA-256 repositories can be added later.
6. **One API, two frontends.** The browser UI consumes the same application services as REST. Server-render an application shell and serve small static JavaScript/CSS assets rather than embedding business rules in the frontend.
7. **Safe reference updates.** Pushes and merges use compare-and-swap semantics under a repository lock. Objects may be written before refs, but refs become visible only after all checks pass.
8. **Reuse the ABAP ecosystem.** A substantial part of HitHub may be inspired by or adapted from abapGitServer and abapGit. Calling abapGit directly is acceptable when its API already provides the required behavior. Add a wrapper only when HitHub needs a different contract, an open-abap substitute or an isolated test seam.
9. **No native Git dependency in production.** Native `git` is an interoperability oracle in tests, not the server implementation. Reused or adapted upstream code must retain required license and attribution notices.

### Upstream reuse strategy

Inspect abapGitServer and abapGit before designing a Git-related component from scratch. Reuse can take any of these forms:

- call a public abapGit class or interface directly;
- copy and adapt compatible ABAP code into HitHub with the required attribution;
- use the upstream implementation as a design and test reference while writing a HitHub-specific implementation;
- write new code only where the upstream behavior does not fit the runtime, API or correctness requirements.

Likely abapGitServer reference areas include ICF routing, repository persistence, Smart HTTP handling, ref updates, repository browsing and merge-request flows. Likely abapGit reuse areas include Git object models, object-ID calculation, pack/delta processing, compression, pkt-line handling, diffs and client interoperability fixtures. Treat these as candidates to verify against the current upstream source, not assumptions that the relevant APIs are stable or open-abap compatible.

For each reused component, record the upstream repository and revision, reuse mode (direct call, adapted copy or inspiration), local changes, license obligations and the tests that protect compatibility. Prefer direct calls when they work in both SAP and open-abap; prefer a small adapter when runtime behavior differs.

### open-abap and transpiler anomaly log

Record every suspected open-abap runtime, database-adapter or ABAP-to-JavaScript transpiler issue in `ANORMALIES.md`. Add the entry as soon as the discrepancy is isolated and before hiding it behind a workaround. Do not use this file for ordinary HitHub defects that reproduce identically on SAP and open-abap.

Each entry must contain:

- a stable identifier, short title and status (`open`, `workaround`, `reported`, `fixed` or `not-an-anomaly`);
- the discovery date and affected open-abap/transpiler package versions;
- the affected ABAP statement, runtime API or adapter;
- a minimal ABAP reproducer and the exact command used to run it;
- expected SAP behavior and actual open-abap behavior;
- impact on HitHub and the smallest safe workaround, if one exists;
- a link to the upstream issue or an explanation of why it has not been reported;
- the regression-test location and the upstream version containing a fix, when known.

Keep resolved entries in `ANORMALIES.md` as a compatibility history. When an upstream fix is adopted, disable the workaround, run the reproducer and full verification suite, then mark the entry `fixed`. Review all open entries before upgrading open-abap or transpiler dependencies and before every release.

### abapGit simplification suggestions

Record opportunities to simplify HitHub by refactoring abapGit in `SUGGESTIONS.md`. Add an entry when a small, generally useful abapGit change would replace copied code, remove a HitHub adapter, expose an existing capability cleanly or make direct reuse possible. Record the suggestion before committing to a larger HitHub-specific workaround.

Each entry must contain:

- a stable identifier, short title and status (`proposed`, `reported`, `accepted`, `implemented`, `declined` or `obsolete`);
- the affected abapGit class, interface or component and the reviewed upstream revision;
- the current integration difficulty and the HitHub code it complicates;
- the smallest proposed refactoring or public API change;
- a short ABAP usage example showing the intended simpler call;
- expected benefits for HitHub and other abapGit consumers;
- the HitHub fallback if the suggestion is not accepted upstream;
- a link to the upstream issue or pull request, when one exists;
- the first abapGit version containing the change, when implemented.

Suggestions must be narrowly scoped and useful to abapGit independently of HitHub. Do not make a HitHub milestone depend on upstream acceptance: keep a local fallback and update the entry when upstream status changes. Review open suggestions before pinning a new abapGit version and before implementing a new adapter or copied implementation.

## 3. Proposed architecture

```text
Git CLI / browser / API client
              |
        HTTP routing layer
      /         |          \
Smart Git    REST API     Web UI
      \         |          /
         Application services
       repositories, refs, PRs, issues
                    |
              Git domain core
 object codec, object graph, pkt-line, pack/delta,
 negotiation, diff, merge, reference transactions
                    |
             Port interfaces
 object store, metadata store, lock, clock, crypto,
 compression, transaction, event sink
             /                 \
       SAP adapters        open-abap adapters
  DB tables, enqueue,      SQLite/files, mutex,
 ICF, request actor       Express ICF shim
```

### Suggested repository layout

```text
src/                         ABAP production sources
  core/                      Git primitives; no HTTP or DB knowledge
  application/               use cases and policies
  infrastructure/            SAP/open-abap-facing adapters
  http/                      Smart HTTP, REST and web handlers
  persistence/               DDIC table definitions, repositories and table mappings
test/                        ABAP Unit-style unit and contract tests
integration/                 Node/native-Git interoperability tests
web/                         source CSS, JavaScript and templates
static/                      built frontend assets served by ABAP
docs/                        architecture decisions and API docs
```

There is no `db/` directory, no hand-written SQL and no migration framework. The database schema exists only as ABAP artifacts: DDIC table, data-element and domain definitions checked in next to the persistence code. Schema changes are applied by activating those artifacts — through a transport on SAP and through the transpiler and database adapter locally — so SAP and local databases cannot drift apart. Design table changes to be additive and activation-safe instead of writing migration logic.

Keep object names within the selected SAP release's naming constraints. Decide the namespace (`ZHI_*`, `/HITHUB/*`, or another registered namespace) before creating persisted ABAP artifacts.

## 4. Core data model

Use metadata tables for product state and a content-addressed object store for Git data. The exact DDIC definitions are ABAP artifacts created in Step 2.

| Aggregate | Minimum fields and constraints |
| --- | --- |
| Repository | ID, unique normalized name, description, default branch, created/updated timestamps |
| Git object | repository or pool, hash algorithm, OID, type, uncompressed size, compressed payload; immutable and content-addressed |
| Reference | repository, full ref name, target OID, symbolic target, version; unique repository/ref |
| Pull request | repository, number, actor label, source repo/ref/OID, target ref/OID, title, body, state, merge result, timestamps |
| Review | pull request, actor label, state, body, commit OID, timestamps |
| Issue | repository, number, actor label, title, body, state, timestamps |
| Comment | subject type/ID, actor label, body, optional path/line/commit coordinates, timestamps |
| Protection rule | repository/ref pattern, required review count, force-push/delete flags |
| Event/audit record | actor, action, subject, request/correlation ID, timestamp, sanitized details |

Repository-local monotonically increasing numbers should identify issues and pull requests. Use optimistic versions for mutable metadata and explicit locks only for ref transactions and number allocation.

## 5. HTTP surface

### Git Smart HTTP

- `GET /{repo}.git/info/refs?service=git-upload-pack`
- `POST /{repo}.git/git-upload-pack`
- `GET /{repo}.git/info/refs?service=git-receive-pack`
- `POST /{repo}.git/git-receive-pack`

Return exact Git media types, pkt-line framing and cache headers. HitHub does not implement repository-level access control. A deployment may protect the whole service using SAP ICF authentication or an upstream HTTP gateway. Request bodies and responses must remain binary-safe end to end.

### REST API

Initial resources:

```text
POST   /api/repos
GET    /api/repos/{repo}
PATCH  /api/repos/{repo}
DELETE /api/repos/{repo}

GET    /api/repos/{repo}/refs
POST   /api/repos/{repo}/refs
PATCH  /api/repos/{repo}/refs/{ref}
DELETE /api/repos/{repo}/refs/{ref}
GET    /api/repos/{repo}/commits/{ref}
GET    /api/repos/{repo}/contents/{path}?ref={ref}
GET    /api/repos/{repo}/compare/{base}...{head}

GET    /api/repos/{repo}/pulls
POST   /api/repos/{repo}/pulls
GET    /api/repos/{repo}/pulls/{number}
PATCH  /api/repos/{repo}/pulls/{number}
POST   /api/repos/{repo}/pulls/{number}/reviews
GET    /api/repos/{repo}/pulls/{number}/merge
PUT    /api/repos/{repo}/pulls/{number}/merge

GET    /api/repos/{repo}/issues
POST   /api/repos/{repo}/issues
PATCH  /api/repos/{repo}/issues/{number}
POST   /api/repos/{repo}/issues/{number}/comments
```

Specify JSON schemas, status codes, validation errors, pagination, filtering and ETags in an OpenAPI document. Prefer stable opaque IDs in payloads while retaining human-readable repository-name routes. Require `If-Match` for destructive or race-prone updates where practical. Use an idempotency key for repository creation and merge requests.

## 6. Implementation steps

Every checkbox is intended to be one isolated deliverable. Complete the checkboxes in order within a step. Keep the main branch runnable after each checkbox. A step is complete only when all of its completion checks pass in CI.

### Step 0 — Confirm scope and compatibility baseline

- [x] Record the minimum supported SAP release.
- [x] Record the supported ABAP language version.
- [x] Select the ABAP object namespace.
- [x] Select the project license.
- [x] Create `ANORMALIES.md` with the required entry template.
- [x] Create `SUGGESTIONS.md` with the required entry template.
- [x] List the supported native Git versions.
- [x] List the supported abapGit versions.
- [x] Inventory reusable Git server components in abapGitServer.
- [x] Inventory reusable Git primitives and services in abapGit.
- [x] Record initial abapGit simplification opportunities in `SUGGESTIONS.md`.
- [x] Map each planned Git component to direct call, adapted copy, inspiration or new implementation.
- [x] Record the upstream revision for every selected reuse candidate.
- [x] Verify license and attribution requirements for every selected reuse candidate.
- [x] Select one GUI Git client for compatibility testing.
- [x] Build a SAP spike that calls abapGit to read one Git object.
- [x] Build an open-abap spike that calls the same abapGit API.
- [x] Build an adapted-code spike for one abapGitServer HTTP flow.
- [x] Write an ADR selecting the Git-object implementation strategy.
- [x] Publish the MVP feature matrix.
- [x] Record maximum repository, object and push sizes.
- [x] Record concurrency and request-timeout targets.
- [x] Record the supported SAP application-server topology.

Completion checks:

- [x] Runtime-target ADR is approved.
- [x] Persistence ADR is approved.
- [x] Dependency-policy ADR is approved.
- [x] Deployment-access ADR is approved.
- [x] MVP scope is approved.

### Step 1 — Bootstrap the dual runtime

- [x] Add the npm package manifest and lockfile.
- [x] Add `abaplint` for static analysis.
- [x] Add the open-abap transpiler and runtime.
- [x] Configure ABAP source discovery.
- [x] Configure strict linting for the selected ABAP version.
- [x] Add the `npm run lint` command.
- [x] Add the `npm run transpile` command.
- [x] Add the `npm run unit` command.
- [x] Add the `npm run start` command.
- [x] Add the aggregate `npm run verify` command.
- [x] Implement a minimal ABAP `IF_HTTP_EXTENSION` handler.
- [x] Implement the `/health` response in ABAP.
- [x] Route the handler through `express-icf-shim` locally.
- [x] Add the selected local database adapter.
- [x] Add a lint CI job.
- [x] Add a transpilation CI job.
- [x] Add a unit-test CI job.
- [x] Add a local HTTP smoke-test CI job.
- [x] Add a CI check that every referenced anomaly regression test exists.

Completion checks:

- [x] One command starts the local server from a clean checkout.
- [x] `/health` reports build, runtime and database status.
- [x] The complete CI workflow passes.

### Step 2 — Establish ports and schema

- [x] Define the object-store ABAP interface.
- [x] Define the metadata-store ABAP interfaces.
- [x] Define the transaction ABAP interface.
- [x] Define the repository-lock ABAP interface.
- [x] Define the hashing ABAP interface.
- [x] Define the compression ABAP interface.
- [x] Define clock and UUID/random ABAP interfaces.
- [x] Define the domain-event sink ABAP interface.
- [x] Define the metadata tables as DDIC artifacts in `src/persistence/`.
- [x] Verify that the transpiled DDIC artifacts create the same local tables and constraints.
- [x] Implement the local repository adapters.
- [x] Implement the SAP repository adapters.
- [x] Implement the local unit-of-work adapter.
- [x] Implement the SAP unit-of-work adapter.
- [x] Add repository, commit and ref fixture builders.
- [x] Add shared persistence contract tests.

Completion checks:

- [x] Persistence contract tests pass against the local adapter.
- [ ] The same tests pass against a configured SAP test system.
- [ ] Rollback behavior is consistent across both adapters.
- [ ] Constraint failures are consistent across both adapters.

### Step 3 — Implement Git object primitives

- [x] Review the current abapGit object implementation and record reusable APIs and code.
- [x] Implement blob encoding and decoding.
- [x] Implement tree encoding and decoding.
- [x] Implement commit encoding and decoding.
- [x] Implement annotated-tag encoding and decoding.
- [x] Implement canonical object-header generation.
- [x] Implement object-ID calculation from `"<type> <size>\0<payload>"`.
- [x] Implement object-ID validation.
- [x] Implement commit identity and timestamp parsing.
- [x] Implement commit parent parsing.
- [x] Implement tree mode parsing and canonical ordering.
- [x] Implement immutable object-store reads.
- [x] Implement immutable object-store writes.
- [x] Implement object reachability walking.
- [x] Implement Git ref-name validation.
- [x] Implement loose-object compression through the compression port.
- [x] Implement loose-object decompression through the compression port.
- [x] Add native Git golden fixtures.
- [x] Add abapGit-produced fixture repositories.
- [x] Add malformed-object fixtures.

Completion checks:

- [x] Normal, empty, binary, non-ASCII and large objects match native Git byte for byte.
- [x] Every generated object ID matches native Git.
- [x] Malformed objects fail without being persisted.

### Step 4 — Implement pack files and deltas

- [x] Review the current abapGit pack/delta implementation and record reusable APIs and code.
- [x] Implement pack-header parsing.
- [x] Implement pack-object entry parsing.
- [x] Implement pack-trailer and checksum validation.
- [x] Implement pack-header emission.
- [x] Implement base-object emission.
- [x] Implement `OFS_DELTA` decoding.
- [x] Implement `REF_DELTA` decoding.
- [x] Add bounds checks to delta instructions.
- [x] Resolve thin-pack bases against repository-visible objects only.
- [x] Implement pack indexing.
- [x] Implement object deduplication during ingestion.
- [x] Add streaming pack input.
- [x] Add streaming pack output.
- [x] Add configurable pack resource limits.
- [x] Limit decompressed object size.
- [x] Limit delta-chain depth.
- [x] Guard pack arithmetic against integer overflow.
- [x] Add a native Git pack corpus.
- [x] Add an abapGit pack corpus.
- [x] Add pack and delta property tests.

Completion checks:

- [x] Unpack/repack round trips preserve every reachable object ID.
- [x] Corrupt packs are rejected without hangs.
- [x] Rejected packs cannot update refs.

### Step 5 — Deliver read-only Smart HTTP

- [x] Review the current abapGitServer upload-pack flow and record reusable APIs and code.
- [x] Implement pkt-line encoding.
- [x] Implement pkt-line decoding.
- [x] Implement protocol v0/v1 capability advertisement.
- [x] Document each supported and unsupported capability.
- [x] Route the upload-pack `info/refs` request.
- [x] Return the exact upload-pack discovery headers and service preamble.
- [x] Route the `git-upload-pack` POST request.
- [x] Implement want/have parsing.
- [x] Implement ACK/NAK negotiation.
- [x] Implement basic shallow-clone negotiation.
- [x] Implement side-band pack output.
- [x] Stream generated pack responses.
- [x] Filter advertised refs through repository visibility rules.
- [x] Add protocol v2 capability advertisement.
- [x] Add protocol v2 `ls-refs`.
- [x] Add protocol v2 `fetch`.

Completion checks:

- [x] Native Git clones an empty repository.
- [x] Native Git clones and fetches branched and tagged repositories.
- [x] Native Git performs an incremental fetch.
- [x] abapGit clones and pulls a fixture repository.
- [x] Captured packet traces match the Git HTTP specification.

### Step 6 — Deliver push support

- [x] Review the current abapGitServer receive-pack flow and record reusable APIs and code.
- [x] Add an optional trusted-runtime actor label to the request context.
- [x] Implement receive-pack capability advertisement.
- [x] Route the receive-pack `info/refs` request.
- [x] Route the `git-receive-pack` POST request.
- [x] Parse receive-pack ref commands.
- [x] Implement receive-pack report-status output.
- [x] Implement receive-pack side-band output.
- [x] Create a quarantine area for incoming objects.
- [x] Validate the complete incoming pack before promotion.
- [x] Validate fast-forward updates.
- [x] Validate updated ref names and target object types.
- [x] Enforce branch-protection rules.
- [x] Enforce configured push-size limits.
- [x] Reject commands whose old object ID is stale.
- [x] Apply multi-ref commands under one repository lock.
- [x] Promote quarantined objects before committing refs.
- [x] Emit a push audit event after a successful commit.
- [x] Add cleanup for abandoned quarantines.

Completion checks:

- [x] Native Git creates, updates and deletes branches over HTTP.
- [x] Native Git pushes and deletes tags over HTTP.
- [x] abapGit pushes a fixture repository.
- [x] Rejected, concurrent and corrupt pushes expose no partial ref state.

### Step 7 — Repository REST APIs

- [x] Implement the central HTTP router.
- [x] Implement JSON request and response serialization.
- [x] Implement the REST request context.
- [x] Implement RFC 9457-style problem responses.
- [x] Supply a fixed actor label in local development.
- [x] Document whole-service protection through SAP ICF.
- [x] Document whole-service protection through an upstream gateway.
- [x] Implement repository creation.
- [x] Implement repository retrieval and listing.
- [x] Implement repository metadata updates.
- [x] Implement repository soft deletion.
- [x] Implement repository purge as a separate operation.
- [x] Implement branch CRUD endpoints.
- [x] Implement tag CRUD endpoints.
- [x] Write the OpenAPI document.
- [x] Add examples and pagination links to OpenAPI.
- [x] Validate REST responses against OpenAPI in tests.
- [x] Add configurable CORS handling.
- [x] Add CSRF protection for deployments using cookie authentication.
- [x] Add request and rate limits.
- [x] Emit audit events for repository mutations.

Completion checks:

- [x] Contract tests cover successful requests.
- [x] Contract tests cover validation failures.
- [x] Contract tests cover actor propagation.
- [x] Contract tests cover concurrent updates.
- [x] Contract tests cover idempotent retries.

### Step 8 — Read-only repository web experience

- [x] Review the current abapGitServer repository browser and record reusable UI flows and ABAP code.
- [x] Build the global page layout.
- [x] Build the repository dashboard.
- [x] Build the repository creation form.
- [x] Build the repository overview page.
- [x] Render repository README files safely.
- [x] Build the branch and tag selector.
- [x] Build the tree browser.
- [x] Build the blob viewer.
- [x] Build commit history.
- [x] Build commit detail.
- [x] Add raw blob download.
- [x] Add source syntax highlighting.
- [x] Build the compare view.
- [x] Build unified diff rendering.
- [x] Build split diff rendering.
- [x] Add Playwright browser end-to-end test infrastructure.
- [x] Add Playwright coverage for repository creation, browsing and comparison.
- [x] Add binary and oversized-file fallbacks.
- [x] Add keyboard navigation and semantic landmarks.
- [x] Add responsive layouts and accessible focus/contrast styles.
- [x] Configure a strict Content Security Policy.
- [x] Escape all repository-provided content by default.
- [x] Sanitize supported Markdown output.

Completion checks:

- [x] A caller creates a repository through the web UI.
- [x] The UI displays the repository clone URL.
- [x] The UI browses every object in the interoperability fixture.
- [x] Accessibility checks pass.
- [x] Supported-browser smoke tests pass.

### Step 9 — Pull-request domain and APIs

- [x] Review the current abapGitServer merge-request flow and record reusable domain behavior and ABAP code.
- [x] Review the current abapGit diff/merge primitives and record reusable APIs and code.
- [x] Define `open`, `closed` and `merged` pull-request transitions.
- [x] Support draft pull requests and the ready-for-review transition.
- [x] Persist immutable head and base snapshots when a PR is opened.
- [x] Implement merge-base calculation.
- [x] Implement ahead/behind counting.
- [x] Implement changed-file calculation.
- [x] Implement patch-summary generation.
- [x] Implement three-way tree merging.
- [x] Implement three-way text-blob merging.
- [x] Defer rename detection behind an explicit capability flag.
- [x] Implement pull-request comments.
- [x] Implement line comments with commit/path/line coordinates.
- [x] Implement reviews and approval/request-changes states.
- [x] Implement `clean`, `conflicting`, `stale`, `blocked` and `unknown` mergeability states.
- [x] Recompute mergeability when the head ref changes.
- [x] Recompute mergeability when the base ref changes.
- [x] Implement target-branch protection in one merge-policy service.
- [x] Implement pull-request REST endpoints.
- [x] Expose draft and ready-for-review state through the pull-request REST endpoints.

Completion checks:

- [x] Domain tests cover clean pull requests.
- [x] Domain tests cover conflicting pull requests.
- [x] Domain tests cover stale pull requests.
- [x] Domain tests cover updates after review.
- [x] Domain tests cover concurrent base movement.
- [x] REST contract tests cover every pull-request state.

### Step 10 — Merge pull requests safely

- [x] Implement the merge-commit strategy.
- [x] Require the expected head object ID in merge requests.
- [x] Acquire the repository lock before final merge validation.
- [x] Recheck the target object ID while holding the lock.
- [x] Validate merge author and committer identities.
- [x] Create the canonical merge commit.
- [x] Persist merged objects before updating the target ref.
- [x] Compare-and-swap the target ref.
- [x] Persist the merged pull-request state.
- [x] Emit merge events through an idempotent recovery workflow.
- [x] Persist the merge result for retry responses.
- [x] Add the merge button to the UI.
- [x] Add draft and ready-for-review actions to the pull-request UI.
- [x] Display blocking and conflict explanations in the UI.
- [x] Add optional post-merge source-branch deletion.
- [x] Add squash merging as a separately testable strategy.
- [x] Add rebase merging as a separately testable strategy.

Completion checks:

- [x] Native Git fetches and validates a UI-created merge.
- [x] Native Git fetches and validates a REST-created merge.
- [x] `git fsck --strict` passes after each merge strategy.
- [x] Double submission produces only one merge result.
- [x] A racing push cannot cause the wrong commits to be merged.

### Step 11 — Issues and collaboration baseline

- [x] Implement issue creation.
- [x] Implement issue editing.
- [x] Implement issue closing and reopening.
- [x] Implement issue comments.
- [x] Implement issue assignees as free-form actor labels.
- [x] Implement issue labels.
- [x] Implement the shared issue/PR timeline model.
- [x] Build issue REST endpoints.
- [x] Build issue web pages.
- [x] Build the repository activity view.
- [x] Build the repository audit view.

Completion checks:

- [x] UI and REST expose equivalent issue workflows.
- [x] Timeline generation is deterministic.
- [x] Timeline entries preserve the optional runtime actor label.

### Step 12 — Hardening and operations

- [x] Add structured application logs.
- [x] Add request correlation IDs.
- [x] Add service metrics.
- [x] Separate liveness and readiness endpoints.
- [x] Redact secrets and repository content from operational telemetry.
- [x] Add request rate limits.
- [x] Add request-body and Git-object quotas.
- [x] Add operation timeouts.
- [x] Add back-pressure for expensive Git operations.
- [x] Write the threat model.
- [x] Resolve SSRF, XSS, CSRF and path-traversal findings.
- [x] Resolve ref-injection, decompression-bomb and hash-collision findings.
- [x] Resolve deployment-boundary findings.
- [x] Write the backup runbook.
- [x] Write the restore runbook.
- [x] Write the DDIC activation and schema-change runbook.
- [x] Verify a restored backup by cloning it and running integrity checks.
- [x] Implement reachability-based garbage collection.
- [x] Protect active temporary and quarantine roots from garbage collection.
- [ ] Add garbage-collection grace periods.
- [ ] Add garbage-collection dry-run reporting.
- [ ] Test locking across multiple SAP application servers.
- [ ] Test SAP failure recovery at each transaction boundary.
- [ ] Review every open `ANORMALIES.md` entry against the currently pinned open-abap versions.
- [ ] Retest every anomaly reproducer on SAP and open-abap.
- [ ] Review every open `SUGGESTIONS.md` entry against the currently pinned abapGit version.
- [ ] Replace local fallbacks when an accepted abapGit simplification is available and verified.

Completion checks:

- [ ] Every threat-model action is closed or explicitly accepted.
- [ ] Load and soak tests meet the Step 0 targets.
- [ ] Backup/restore tests meet the Step 0 targets.
- [ ] Injected-failure tests preserve repository consistency.

### Step 13 — Release the MVP

- [ ] Publish SAP ICF installation instructions.
- [ ] Publish SAP DDIC installation and activation instructions.
- [ ] Publish local open-abap setup instructions.
- [ ] Publish administrator configuration documentation.
- [ ] Publish the REST API contract.
- [ ] Publish backup and recovery documentation.
- [ ] Publish upgrade documentation.
- [ ] Publish the supported Git capability matrix.
- [ ] Document the unversioned API compatibility policy.
- [ ] Run end-to-end tests with every supported native Git version.
- [ ] Run end-to-end tests with every supported abapGit version.
- [ ] Run end-to-end tests with every supported browser.
- [ ] Produce the release artifact.
- [ ] Produce the DDIC artifact package.
- [ ] Publish the changelog.
- [ ] Publish known limitations.
- [ ] Review unresolved `ANORMALIES.md` entries for release impact.
- [ ] Include applicable unresolved anomalies in the release known limitations.
- [ ] Update `SUGGESTIONS.md` with the abapGit revisions verified for the release.

Completion checks:

- [ ] A new administrator completes the documented installation.
- [ ] The administrator protects the whole service at the deployment boundary when required.
- [ ] The administrator creates a repository.
- [ ] abapGit pushes a repository.
- [ ] The administrator opens, reviews and merges a pull request.
- [ ] Native Git clones the merged result.

## 7. Test strategy

### Unit tests

- Pure ABAP tests for codecs, pkt-lines, deltas, graph walks, diffs, merge rules and state machines.
- Golden vectors for every binary format; never compare only semantic output when byte compatibility matters.
- Deterministic clock, actor, compression and storage fakes.

### Contract tests

- Run the same object-store, metadata-store, lock and transaction behavior suite against each adapter.
- Validate every REST response against OpenAPI and every error against one problem-details schema.

### Interoperability tests

- Launch the transpiled server on an ephemeral port and use native `git clone`, `fetch`, `push`, tag and branch commands against it.
- Run Playwright browser end-to-end tests against the local server, including repository browsing, draft pull requests, reviews and merges.
- Exercise abapGit HTTP behavior with captured/replayable fixtures plus a scheduled real-client SAP test where available.
- Run `git fsck --strict` on repositories cloned after pushes and PR merges.
- Keep packet traces and minimal repository fixtures for regressions, with credentials redacted.

### Resilience and security tests

- Property/fuzz tests for pkt-line, object, pack, delta and ref parsers.
- Concurrent push/merge tests and injected failures at every quarantine/transaction/ref-update boundary.
- Tests showing that optional deployment actor headers are trusted only from the configured adapter/gateway.
- XSS/Markdown, CSRF, rate-limit and oversized-input cases.

### Browser end-to-end tests

- Use Playwright with deterministic fixtures and a fresh test database per run.
- Cover keyboard navigation, responsive layouts and accessible names/landmarks in the browser UI.
- Run the Playwright suite in CI against every supported browser and retain traces/screenshots for failures.

## 8. Milestones

| Milestone | Steps | Demonstrable outcome |
| --- | --- | --- |
| M0: Executable skeleton | 0–2 | Same ABAP health service and persistence contracts run locally and on SAP |
| M1: Read-only Git server | 3–5 | Native Git and abapGit clone/fetch repositories over HTTP |
| M2: Collaborative repositories | 6–8 | Callers create, push and browse repositories without HitHub account setup |
| M3: Pull requests | 9–10 | Callers review and safely merge branches; clients fetch the result |
| M4: MVP | 11–13 | Issues, operations, security, docs and release acceptance are complete |

Do not estimate calendar dates until Step 0 establishes runtime constraints and a spike proves pack/delta performance in both SAP and open-abap. Track effort and risk per step after those measurements.

## 9. Principal risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Binary/stream behavior differs between ICF and the Node shim | Add an HTTP binary echo spike and shared adapter contract tests in Step 1 |
| Pack/delta processing exceeds SAP memory or request time | Stream, cap inputs and delta depth, benchmark early, and keep negotiation/packing resumable where possible |
| Reused abapGit/abapGitServer code changes upstream or behaves differently in open-abap | Record upstream revisions and reuse mode, pin direct dependencies, add compatibility tests, and introduce an adapter only where runtime substitution is needed |
| DB and Git ref transactions cannot be committed atomically | Use a repository lock, compare-and-swap refs and an idempotent journal/recovery workflow |
| Cross-repository object deduplication exposes unreachable data through object APIs | Begin with repository-scoped storage; introduce shared pools only with explicit reachability checks |
| Git protocol breadth delays a usable release | Advertise only implemented capabilities and use a published compatibility matrix |
| “Basic GitHub functionality” expands without a boundary | Treat Section 1 as the MVP contract and move new product areas to the post-MVP backlog |

## 10. Post-MVP backlog

- Protocol v2 completeness and partial clone/filter support.
- Forks and cross-repository pull requests.
- Releases and downloadable assets.
- Webhooks and external status/check APIs.
- Protected-branch required checks and CODEOWNERS-like review rules.
- Search, blame, archive download and richer Markdown rendering.
- Import/mirroring from existing Git servers.
- Optional native object-storage adapters and safe cross-repository deduplication.
- SHA-256 repository format after supported clients and internal interfaces are verified.
- CI runner orchestration as an independent product.

## 11. Reference specifications and upstream projects

- [Git HTTP protocol](https://git-scm.com/docs/http-protocol)
- [Git protocol v2](https://git-scm.com/docs/protocol-v2)
- [Git pack format](https://git-scm.com/docs/gitformat-pack)
- [git-http-backend behavior](https://git-scm.com/docs/git-http-backend)
- [abapGitServer](https://github.com/larshp/abapGitServer)
- [abapGit](https://github.com/abapGit/abapGit)
- [open-abap](https://open-abap.org/)
- [open-abap Express ICF shim](https://github.com/open-abap/express-icf-shim)
