# Known limitations for the MVP

This document is part of the unreleased MVP baseline. It distinguishes
intentional scope limits from verification that still requires a target
environment.

The release review found no unresolved entries in `ANORMALIES.md`; there are
no applicable open-abap or transpiler anomalies to carry into this document.

## Deployment and security boundary

- HitHub does not provide a user directory, login flow, collaborators,
  repository roles, or per-repository authorization. SAP ICF or a trusted
  upstream gateway must authenticate and protect the entire service.
- TLS, gateway authentication, actor-header trust, cluster-wide rate and
  concurrency limiting, backup tooling, and SAP application-server hardening
  are deployment responsibilities.
- Multi-server SAP deployments require shared database persistence and SAP
  enqueue locking. Local open-abap is a single-process development/test
  runtime and is not a scale-out substitute.

## Compatibility and verification

- Git 2.43.0 is the current local native-client baseline. Git 2.30 and 2.39
  remain supported targets in the published matrix but need their client
  binaries in the test environment for release execution.
- abapGit v1.131.0 through v1.134.0 are the initial compatibility targets;
  captured fixtures are available, while real-client SAP runs depend on a
  configured SAP test system.
- The SAP ICF, DDIC activation, and multi-application-server lock procedures
  are documented but cannot be fully exercised in the local open-abap runtime.
- The browser assets ship as MIME repository objects and are served by the
  ABAP handler, but they address `/api/...` and `/ui/...` from the host root.
  A service published below a path prefix serves the shell and returns its
  own assets, while the shell's API calls and route links resolve against the
  host root. Until the frontend derives a base path, expose the UI at a host
  root through the reverse proxy or Web Dispatcher; a prefixed path is
  supported for the REST and Git endpoints only.
- MIME repository reads are not exercised by the local runtime, which
  registers the same serialized assets into its own in-memory adapter.
  Confirm the assets after the first import in the target system.
- The selected Git GUI client and all supported browsers require their
  binaries and host dependencies to be installed before CI execution.

## Product scope

The MVP does not include SSH transport, Git LFS, Dumb HTTP, packages, Pages,
wikis, projects, Sponsors, organizations, federation, outbound repository
imports, webhooks, or CI runners. These require an explicit scope and security
decision before implementation.

## Runtime and operations

- The local database, in-memory rate limiter, and process-local concurrency
  admission are for development/test use. SAP or a gateway must provide
  durable, shared equivalents where required.
- The initial resource and timeout values are safety targets, not universal
  sizing recommendations. Administrators must review them against SAP memory,
  request-time, storage and backup capacity before increasing them.
- Reachability garbage collection protects refs and active quarantine roots,
  but administrators must review dry-run reports and retain the configured
  grace period before deletion.
- The API is unversioned. Clients must follow the published compatibility
  policy and treat documented error responses as retry or user-action cases.
