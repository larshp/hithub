# ADR 0002: Runtime target

- Status: approved for the MVP baseline
- Date: 2026-08-27

## Decision

HitHub targets SAP NetWeaver AS ABAP 7.55 or later using the standard
ABAP language version, with `IF_HTTP_EXTENSION` as the SAP entry point. The
same ABAP behavior is transpiled and run locally on Node.js through the
open-abap runtime and an Express ICF shim.

SAP deployments may use one or more stateless application servers behind a
gateway, provided database persistence and enqueue locking are shared. Local
development uses one Node.js process and a local database adapter. Runtime
specific behavior stays behind infrastructure ports.

## Rationale

The release floor supports the classic ICF integration required by the product
while keeping the ABAP source portable to the local runtime. It is set by the
language features the core relies on rather than by ICF alone: the built-in
type `int8` (7.54) carries object sizes, pack offsets and optimistic-locking
versions, and `CL_ABAP_CODEPAGE` (7.53) performs every byte/text conversion.
The standard language version is required for on-premise ICF and persistence
integration; Cloud Development is not the target. Native Git is test-only.

## Consequences

Every SAP-only API must be isolated and every open-abap discrepancy must be
recorded in `ANORMALIES.md`. The compatibility and deployment baselines are
documented in `docs/compatibility.md` and `docs/deployment-topology.md`.
