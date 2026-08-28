# SAP ICF access protection

HitHub relies on the SAP ICF service boundary for whole-service
authentication and transport protection. It does not implement a user
directory, repository roles, or per-repository authorization.

## Configure the service

1. Activate the SICF node chosen by the installation transport and assign
   `ZCL_HITHUB_HTTP` as its HTTP extension handler.
2. Require authentication on that node and every parent node that can route
   requests to it. Use the organization's approved SAP authentication
   procedure, such as SAML, X.509, or a protected logon ticket flow.
3. Require HTTPS at the ICM/Web Dispatcher boundary. Redirecting HTTP is not
   sufficient for Git credentials or repository data.
4. Restrict administration of the SICF node and its authentication settings
   to the deployment administrators.
5. Configure the trusted actor adapter, if actor labels are enabled. The
   application must receive a validated actor label from that adapter; it
   must not treat an arbitrary client header as identity.

The protection applies to `/health`, every `/api/*` endpoint, and all Git
Smart HTTP discovery and pack endpoints below the service node. A successful
authentication at the node grants the same HitHub capability set to the
caller; repository-level authorization is outside the MVP boundary.

## Verify the boundary

Use an unauthenticated request and an authenticated request from a controlled
client:

- the unauthenticated request is rejected by ICF or the upstream SAP gateway
  before the ABAP handler runs;
- the authenticated request reaches `/health` and returns the normal health
  document;
- authenticated Git discovery returns its binary Git media type and pkt-line
  body unchanged;
- authenticated Git push and REST requests preserve binary request bodies;
- server and gateway logs do not record credentials, authorization headers,
  pack contents, or repository object payloads.

Repeat the checks after every transport or SICF authentication change. Keep
the service node protected in every client, QA, and production system; local
open-abap development uses its separate fixed local actor configuration.
