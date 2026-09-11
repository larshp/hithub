# ADR 0003: Persistence boundary

- Status: approved for the MVP baseline
- Date: 2026-08-27

## Decision

Product metadata and Git objects are persisted through ABAP ports. The SAP
adapter uses DDIC tables and database transactions; the local adapter uses the
selected open-abap SQLite database adapter. The same ABAP repository contracts
and constraint tests run against both adapters.

DDIC table, domain, and data-element definitions are checked into
`src/persistence/` as ABAP artifacts. There is no `db/` directory, handwritten
SQL, or migration framework. Schema changes are additive and activation-safe;
SAP activation applies them through transport, while local transpilation and
the database adapter create the equivalent tables and constraints.

Git objects begin repository-scoped and immutable. Metadata updates use
optimistic versions. Ref transactions and repository-local number allocation
use the repository lock and unit-of-work ports, with compare-and-swap checks
before visibility.

## Rationale

This keeps ABAP authoritative and prevents SAP/local schema drift while
allowing deterministic local tests. Repository-scoped storage avoids exposing
unreachable objects through a future shared object pool.

## Consequences

The schema must be expressed using features supported by both the minimum SAP
release and the local adapter. Every constraint and rollback behavior needs a
shared contract test, and SAP activation remains an environment prerequisite
for the SAP completion checks.
