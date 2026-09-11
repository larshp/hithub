# Unversioned API compatibility policy

HitHub’s public REST routes are unversioned in their URL. The OpenAPI document
describes the current contract; its `info.version` identifies the contract
revision and is not a URL version selector. Git Smart HTTP follows the
published protocol and capability matrix rather than a HitHub-specific URL
version.

## Compatibility guarantees

- Existing REST routes, methods, success status codes, problem-media type,
  required request fields, and documented response fields remain compatible
  within an MVP release line.
- New response fields, new list items, optional request fields, and new
  capability advertisements are additive only when older clients can safely
  ignore them.
- Existing JSON field meanings, identifier formats, ref semantics, ETag/
  `If-Match` behavior, idempotency behavior, and error status meanings do not
  change silently.
- Git discovery, pkt-line framing, media types, and advertised capability
  semantics remain compatible. A capability is advertised only after its
  server behavior and client interoperability tests are available.
- Unknown request fields are rejected where the OpenAPI schema marks
  `additionalProperties: false`; clients must not depend on silently accepted
  extension fields.

## Deprecation

To deprecate a route, field, capability, or header, document the replacement
and reason in the changelog and contract, keep the old behavior working for at
least one published release line, and add a regression test. Emit a safe
deprecation signal only through documented headers or problem details; never
put credentials or repository content in it. Remove the old behavior only in
an explicitly announced breaking release.

## Breaking changes

A changed URL, method, required field, status meaning, identifier format,
ref-update rule, or Git capability behavior is a breaking change. Before
shipping one:

1. update the OpenAPI contract, capability matrix, compatibility document and
   changelog together;
2. provide a migration and rollback path for durable data and DDIC artifacts;
3. run REST, native Git interoperability, browser, backup/restore, and failure
   regression suites; and
4. publish the new contract revision and obtain administrator sign-off.

If a breaking change cannot be isolated behind an explicit opt-in or a new
deployment release, keep the existing behavior and record the limitation in
the known-limitations document.

## Client responsibilities

Clients should ignore unknown response fields, preserve opaque IDs and ETags,
send `If-Match` for race-prone updates, and handle documented `409`, `412`,
`428`, `429`, `503`, and `504` responses as retry or user-action cases. Git
clients should negotiate only advertised capabilities and fall back to the
published v0/v1 behavior when protocol-v2 is unavailable.
