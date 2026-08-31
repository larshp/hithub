# Upstream gateway access protection

An upstream gateway may protect the complete HitHub service when SAP ICF is
not the public authentication boundary. The gateway must authenticate the
caller before forwarding any request to the ABAP handler and must apply one
consistent policy to health, REST, and Git routes.

## Required gateway policy

- Terminate TLS only with the organization's approved certificates and
  protocols, or forward the request over a separately protected TLS hop.
- Require the approved authentication mechanism for the whole HitHub route
  prefix. Do not expose `/health`, `/api/*`, or `*.git/*` as unauthenticated
  exceptions.
- Strip any client-supplied actor or identity headers before authentication.
  If actor propagation is enabled, set the trusted actor value only from the
  gateway's authenticated identity mapping.
- Preserve `Content-Type`, `Content-Length`, `Git-Protocol`, query strings,
  and the request and response bodies byte for byte. Do not parse, compress,
  cache, or rewrite Git pack traffic.
- Enforce gateway request size, timeout, and connection limits at least as
  strictly as the HitHub deployment limits, and return a safe error without
  logging request bodies.
- Redact authorization credentials, actor headers, pack data, and repository
  content from access and error logs.

## Route verification

From a controlled client, verify that an unauthenticated request to each of
`/health`, `/api/repos`, and a Git `info/refs` URL is rejected at the gateway.
Then verify with an authenticated client that:

1. `/health` reaches the ABAP handler;
2. Git discovery retains its exact Git media type and pkt-line body;
3. clone, fetch, and push bodies pass through without textual conversion;
4. REST JSON requests and problem responses retain their content types; and
5. a duplicate or forged actor header cannot replace the gateway-provided
   actor label.

Keep the gateway policy and route-prefix ownership in infrastructure
configuration under review. HitHub remains intentionally unaware of gateway
credentials and does not implement repository-level authorization.
