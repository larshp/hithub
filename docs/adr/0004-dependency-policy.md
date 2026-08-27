# ADR 0004: Dependency policy

- Status: approved for the MVP baseline
- Date: 2026-08-27

## Decision

Runtime dependencies must be necessary, license-compatible, and pinned for
release builds. ABAP source dependencies are reviewed at immutable upstream
revisions and their reuse mode is recorded in `docs/reuse-strategy.md`.
Node.js dependencies are committed through `package-lock.json`; production
behavior must not invoke native Git or depend on a hosted service.

The initial approved upstream sources are abapGitServer revision
`3808345145b4d0fa78c74cbabf4964383c1aa1ad` and abapGit revision
`d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`, both reviewed as MIT. Any new
source or bundled asset requires a license/attribution entry before import.

Direct calls to upstream ABAP classes require successful SAP and open-abap
spikes. Otherwise, use a small adapter or an attributed adapted copy. Avoid
unnecessary dependencies on UI libraries, database-specific SQL, and SAP-only
APIs in the core.

## Consequences

Release preparation must reproduce dependency resolution from the lockfile and
verify the recorded upstream revisions. Updating open-abap, the transpiler,
abapGit, or abapGitServer requires reviewing open anomalies, suggestions,
license notices, and compatibility fixtures.
