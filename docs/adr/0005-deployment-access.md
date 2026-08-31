# ADR 0005: Deployment access boundary

- Status: approved for the MVP baseline
- Date: 2026-08-27

## Decision

HitHub does not implement a user directory, login flow, collaborators, or
repository roles. Deployments protect the entire ICF service at the SAP ICF
authentication boundary or at a trusted upstream gateway. Every admitted
caller receives the same HitHub capabilities.

The application may consume an optional actor label only from the configured
SAP/gateway adapter. Raw client headers are never trusted as actor identity.
The adapter validates and normalizes the actor before placing it in the
request context. Local development uses a fixed configured actor label.

The deployment boundary is responsible for TLS termination or end-to-end TLS,
authentication, session/cookie policy, and coarse service access. HitHub still
validates all repository input, applies CSRF protection where cookie
authentication is used, and emits sanitized audit records.

## Consequences

Installation documentation must provide both SAP ICF and upstream-gateway
protection examples. Fine-grained authorization is explicitly outside the MVP;
introducing it later requires a new domain and API decision rather than
implicit header checks.
