# Supported SAP application-server topology

The MVP supports SAP NetWeaver AS ABAP 7.52 SP04 or later in either of these
forms:

- a single application server with the standard SAP database and enqueue
  service; or
- multiple application servers behind SAP Web Dispatcher or an equivalent
  gateway, all using the same SAP database and enqueue service.

HitHub ICF handlers are request-stateless. Repository metadata and Git objects
are stored in shared SAP persistence, and repository ref transactions acquire
the shared enqueue/repository lock so a request routed to any application
server observes the same compare-and-swap state. Temporary quarantine data
must use storage visible to the worker that owns the request and must be
recoverable/cleanable after worker failure.

The MVP does not support application-server-local persistence, a load-balanced
deployment without shared locking, or active-active nodes with independently
managed databases. The local open-abap runtime is a separate single-process
development/test topology and is not a SAP scale-out target.

## Local development CORS

The local HTTP host leaves CORS disabled unless `HITHUB_CORS_ORIGIN` is set.
Set it to one origin or a comma-separated allowlist, for example
`HITHUB_CORS_ORIGIN=https://console.example.test,http://localhost:4000`.
The host then emits the CORS allow headers and answers allowed preflight
requests with `204 No Content`; origins not in the allowlist receive no CORS
grant. Configure the equivalent origin policy at SAP ICF or the upstream
gateway for SAP deployments.

## Cookie authentication and CSRF

When the local host is configured with `HITHUB_COOKIE_AUTH=true`, every
state-changing request must provide the same value in the `hithub_csrf` cookie
and the `X-CSRF-Token` header. The cookie name is configurable with
`HITHUB_CSRF_COOKIE`. Preflight requests remain unauthenticated and are handled
by the CORS policy. SAP deployments should enable the equivalent CSRF control
in the cookie-authentication gateway or ICF security layer.

## Request and rate limits

The local host accepts a configurable request body limit through
`HITHUB_BODY_LIMIT` (default `64mb`) and an in-memory per-client rate limit
through `HITHUB_RATE_LIMIT` and `HITHUB_RATE_WINDOW_MS` (defaults `300` and
`60000`). Oversized requests return `413`; throttled requests return `429` with
`Retry-After`. The in-memory limiter is for single-process development only;
SAP scale-out deployments should enforce equivalent limits at Web Dispatcher
or the upstream gateway.
