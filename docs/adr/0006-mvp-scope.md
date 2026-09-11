# ADR 0006: MVP scope

- Status: approved for the MVP baseline
- Date: 2026-08-27

## Decision

The MVP scope is the capability set in `docs/mvp-feature-matrix.md`: dual
SAP/open-abap runtime, repository administration, Smart HTTP clone/fetch/push,
Git object and ref browsing, REST APIs, responsive read/write collaboration UI,
pull requests with safe merges, issues/comments, and operational hardening.

The explicit non-goals in that matrix are excluded from the MVP and require a
separate scope decision to promote. Account setup and fine-grained repository
authorization remain deployment concerns, not hidden application features.

## Acceptance

The scope is approved for implementation. A feature is considered delivered
only after its plan checkbox and step completion checks pass. Compatibility,
resource, concurrency, topology, and license decisions in the other approved
ADRs are part of this scope baseline.
