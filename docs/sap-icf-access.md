# SAP ICF installation and access protection

## Prerequisites

Use SAP NetWeaver AS ABAP 7.55 or a later supported release. Install the
HitHub ABAP sources and `ZHI_*` DDIC artifacts through the approved transport
or abapGit process. The namespace must be registered before importing the
transport, and the target system must have a configured database backup and
restore procedure.

Activate the DDIC artifacts and dependent classes in the order described by
the [DDIC activation runbook](ddic-schema-runbook.md). Do not expose the ICF
node until the schema verifier and the basic repository/object persistence
checks have passed in the target system.

## Package structure

The repository is serialized for abapGit with `STARTING_FOLDER` `/src/` and
`PREFIX` folder logic, so the target packages have to be created with these
names before the pull:

| Package | Folder | Contents |
| --- | --- | --- |
| `ZHITHUB` | `/src/` | Root package |
| `ZHITHUB_CORE` | `/src/core/` | Domain and Git object model |
| `ZHITHUB_FRONTEND` | `/src/frontend/` | Browser UI MIME objects |
| `ZHITHUB_HTTP` | `/src/http/` | ICF handler and REST routes |
| `ZHITHUB_INFRA` | `/src/infrastructure/` | Persistence selection and unit of work |
| `ZHITHUB_INFRA_LOCAL` | `/src/infrastructure/local/` | open-abap adapters |
| `ZHITHUB_INFRA_SAP` | `/src/infrastructure/sap/` | SAP adapters |
| `ZHITHUB_PERSISTENCE` | `/src/persistence/` | DDIC artifacts |

`npm run serialize:check` fails when a class, interface, or package is missing
its serialized metadata, and CI runs it, so a new object cannot reach the
repository in a state abapGit would skip on import.

## Persistence adapters

`ZCL_HITHUB_PERSISTENCE` selects the adapters the handler runs on and defaults
to the SAP set, so an installed service needs no configuration:

- `ZCL_HITHUB_UNIT_WORK` commits through `COMMIT WORK AND WAIT`. It is the
  only unit of work and is not selected by mode: `COMMIT WORK` and
  `ROLLBACK WORK` end the LUW in both runtimes.
- `ZCL_HITHUB_SAP_REPO_LOCK` serializes writers through the enqueue server
  using lock object `EZHI_REPO` over `ZHI_REFERENCE`. Confirm the lock object
  activated and that `ENQUEUE_EZHI_REPO` was generated with a `REPOSITORY_ID`
  parameter before the first merge or browser file edit; the lock is what keeps
  two application servers from racing on the same reference.
- `ZCL_HITHUB_SAP_META_STORE` and `ZCL_HITHUB_SAP_OBJECT_STORE` inherit the
  Open SQL implementations unchanged.

The open-abap deployment calls `ZCL_HITHUB_PERSISTENCE=>USE_OPEN_ABAP` during
startup, because it holds the repository lock in process memory and serves the
browser assets from its own in-memory store instead of the MIME repository.
Never select that mode on an application server: the lock would not serialize
anything beyond a single work process.

## Browser UI assets

The browser UI is part of the installed service. `/src/frontend/` holds the
assets as abapGit `SMIM` objects, so the import creates the MIME repository
folder `/SAP/PUBLIC/zhithub` and the objects `index.html`, `app.js` and
`styles.css` below it. There is no separate web server, build step or file
system copy: `ZCL_HITHUB_SAP_ASSET_STORE` reads the objects back through
`CL_MIME_REPOSITORY_API` and `ZCL_HITHUB_STATIC_FILES` answers with them.

1. Confirm after the import that the folder and the three objects exist, for
   example in the MIME repository browser of transaction `SE80`. abapGit
   serializes the folder as its own object next to the files; if an import
   reports a missing folder, repeat the pull once so the folder object is
   created first.
2. `ZHITHUB_FRONTEND` transports like any other package. Assets and ABAP
   classes belong in the same transport, because the shell and the REST
   routes it calls are released together.
3. The handler resolves requests from the ICF path info, so the service node
   prefix does not have to be stripped anywhere:
   - `<node>/` and `<node>/ui/...` answer with `index.html`,
   - `<node>/app.js` and `<node>/styles.css` answer with those objects,
   - anything else keeps the `404` of the REST and Git routes.
4. Responses carry an `ETag` over the asset bytes and `Cache-Control:
   no-cache`, so a browser revalidates and a transported asset change takes
   effect on the next request. A repeated request with `If-None-Match`
   answers `304`.

The assets request `/api/...` and route on `/ui/...` as absolute paths, so the
service has to be reachable at a host root. Publish it through the reverse
proxy or Web Dispatcher rule that maps the host root to the ICF node, and see
the [known limitations](known-limitations.md) before exposing the UI on a
prefixed path.

## Create the ICF service

1. In transaction `SICF`, create or select a dedicated HTTPS service below the
   organization's approved virtual host. The example service path is
   `/default_host/hithub`; a customer namespace or reverse-proxy prefix may
   be used if it is kept stable in the Git remote URLs.
2. In the service's **Handler List**, add the HTTP extension class
   `ZCL_HITHUB_HTTP`.
3. Keep the handler request-stateless. Do not add session state or a second
   application handler that parses Git request bodies.
4. Activate the service and its parent nodes. Route the complete service path
   through HTTPS; the Git remote then has the form
   `https://host.example/hithub/repository.git`.
5. If multiple application servers are used, route them to the same SAP
   database and enqueue service. Follow the [supported topology](deployment-topology.md)
   and run the repository-lock deployment test before production use.

## Configure authentication

HitHub relies on the SAP ICF service boundary for whole-service
authentication and transport protection. It does not implement a user
directory, repository roles, or per-repository authorization.

## Protect the service

1. Require authentication on that node and every parent node that can route
   requests to it. Use the organization's approved SAP authentication
   procedure, such as SAML, X.509, or a protected logon ticket flow.
2. Require HTTPS at the ICM/Web Dispatcher boundary. Redirecting HTTP is not
   sufficient for Git credentials or repository data.
3. Restrict administration of the SICF node and its authentication settings
   to the deployment administrators.
4. Configure the trusted actor adapter, if actor labels are enabled. The
   application must receive a validated actor label from that adapter; it
   must not treat an arbitrary client header as identity.

For a gateway-fronted service, keep authentication at the gateway or at ICF,
but apply one policy to the entire service path. The [gateway policy](upstream-gateway-access.md)
lists the required byte-preserving and logging rules.

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

## Post-install smoke check

Run these checks from a controlled authenticated client, replacing the host,
service path and repository name with the values configured above:

```sh
curl --fail --silent --show-error \
  https://host.example/hithub/health
git clone https://host.example/hithub/repository.git
git -C repository fsck --strict
```

The health response must be JSON, the clone must retain the Git Smart HTTP
content type and pkt-line framing, and `git fsck --strict` must complete
without errors. A failed authentication, schema, or integrity check is a
deployment failure; keep the service unavailable until it is corrected.
