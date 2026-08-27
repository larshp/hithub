# abapGitServer reusable-component inventory

Inventory date: 2026-08-27

Upstream project reviewed: [larshp/abapGitServer](https://github.com/larshp/abapGitServer),
branch `main`, reviewed at full commit
`3808345145b4d0fa78c74cbabf4964383c1aa1ad`. This document satisfies the Step 0
inventory checkbox; the revision is also recorded in
[upstream-revisions.md](upstream-revisions.md). It does not copy code or
approve a license plan; those decisions are recorded by later checkboxes.

## Component inventory

| Upstream area | Observed components and responsibility | HitHub areas to inspect | Initial reuse value |
| --- | --- | --- | --- |
| `src/service` | `zcl_ags_service_git` and its test class; Git HTTP service entry point. `zcl_ags_service_rest` and its test class; REST service entry point. `zcl_ags_service_static`; static-asset serving. `zcl_ags_sicf` and `zif_ags_service`; ICF dispatch/contract. The package also contains the SICF service definition and repository snapshot type. | Step 1 HTTP shim; Steps 5–7 HTTP routing and REST; Step 8 static UI | High for routing and request/response flow; compatibility with HitHub ports is unverified. |
| `src/backend` | Repository and Git-domain behavior, including the observed `zcl_ags_repo` repository aggregate and `zcl_ags_obj_commit` object implementation. This is the likely home for branch, commit, tree/blob, ref, and merge-request behavior. | Steps 2–6 Git storage/protocol; Steps 9–10 pull requests and merges | High as a design and test reference; individual APIs must be reviewed before reuse. |
| `src/database` | Database access and derived repository data, including the observed `zcl_ags_db_tree_cache` cache component. The upstream README and migration notes identify repository/object persistence such as `ZAGS_REPOS` and `ZAGS_OBJECTS`. | Step 2 persistence ports, schema, migrations, and local adapter | Medium: useful table/lookup behavior, but HitHub requires adapter boundaries and stronger transaction/CAS semantics. |
| `src/ddic` | Transportable DDIC artifacts for repository metadata, Git objects, refs/tree cache, and related structures. Exact table definitions are intentionally deferred to the DDIC review. | Step 2 SAP schema and migration design | Medium as a schema reference; not a drop-in schema because HitHub has a broader domain model. |
| `src/frontend` | ABAP-rendered administrative and repository UI, including repository start/create/browse/delete flows. The README describes web repository browsing and creation. | Step 8 web experience; selected administrative workflows in Steps 7 and 11 | Medium as an ABAP UI flow reference; HitHub’s frontend and content-safety policy are different. |
| tests and performance programs | Service test classes plus `zags_test_performance`; the README identifies `abap_db_preparator` for testing. | Steps 1–6 contract, interoperability, and performance tests | Useful fixtures and test-shape reference; test portability is unverified. |

## Capability boundary observed from the upstream documentation

The upstream README describes:

- an SAP ICF service named `ZABAPGITSERVER`;
- Git use through abapGit and command-line `git pull`/clone;
- repository browsing and creation in the web interface;
- merge requests between two branches of the same repository;
- historical tag support, while the scope section still contains older “no
  tags” wording, so tag behavior requires source-level verification;
- no submodules or blame support in the documented scope.

The README lists ABAP-Swagger, abapGit, and `abap_db_preparator` as project
requirements or testing dependencies. Their current versions and license
obligations are not inferred here.

## Follow-up review queue

1. Capture the exact upstream commit for every candidate (Step 0).
2. Inspect Git service methods and packet handling before deciding whether to
   adapt or replace them (Step 5).
3. Inspect receive-pack and ref-update behavior separately (Step 6).
4. Compare repository/object persistence with HitHub’s port and CAS model
   (Step 2).
5. Review frontend escaping and merge-request behavior before using any UI
   code (Steps 8–10).

Sources: [upstream README](https://github.com/larshp/abapGitServer/blob/main/README.md),
[upstream source layout](https://github.com/larshp/abapGitServer/tree/main/src),
and [upstream service package](https://github.com/larshp/abapGitServer/tree/main/src/service).
