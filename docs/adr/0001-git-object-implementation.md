# ADR 0001: Git-object implementation strategy

- Status: accepted for the MVP baseline
- Date: 2026-08-27

## Decision

HitHub will own an algorithm-aware Git-object core in ABAP behind the object,
hashing, compression, and object-store ports. The MVP interoperates with
SHA-1 Git repositories, but public contracts represent an OID as an algorithm
plus opaque bytes/string rather than assuming 40 hexadecimal characters.

The core will use abapGit as the primary behavior and test reference. Stable,
pure Git routines may be adapted into HitHub when they fit the port contracts;
each adapted portion keeps the MIT attribution recorded in
`docs/attributions.md`. Direct calls are limited to APIs that pass both the
SAP and open-abap compatibility checks. SAP HTTP, persistence, locking, streaming limits,
quarantine, and reference compare-and-swap remain HitHub-owned adapters and
services.

Native Git is the byte-compatibility oracle. Every codec and object-ID rule is
protected by golden fixtures and malformed-input tests before it is used by
the Smart HTTP server. HitHub will not invoke a native Git executable in
production.

## Context

abapGit provides useful commit/tag/pack/delta, hashing, compression, and
transport code, while abapGitServer provides server-side HTTP flow patterns.
Neither project’s client-oriented APIs fully express HitHub’s algorithm-aware
contracts, streaming/resource limits, quarantine, or atomic ref-update rules.
The dual SAP/open-abap target also requires explicit seams where runtime
behavior differs.

## Alternatives considered

- Directly depend on abapGit’s internal Git classes: rejected because it would
  couple server contracts to client internals and fixed SHA-1 types.
- Implement every Git primitive without upstream reference: rejected because
  it duplicates mature behavior and increases interoperability risk.
- Invoke native Git: rejected because native Git is explicitly a test oracle,
  not a production dependency.

## Consequences

HitHub owns compatibility maintenance and must re-run the anomaly and golden
fixture suites when abapGit or open-abap changes. In return, the core remains
testable without SAP, can enforce server safety limits, and can add SHA-256
support without redesigning public ports.
