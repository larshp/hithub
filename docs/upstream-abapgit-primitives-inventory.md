# abapGit reusable Git-primitives and services inventory

Inventory date: 2026-08-27

Upstream project reviewed: [abapGit/abapGit](https://github.com/abapGit/abapGit),
the supported `v1.134.0` tag at full commit
`b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f`. This document satisfies the Step 0
inventory checkbox; the revision is also recorded in
[upstream-revisions.md](upstream-revisions.md). It does not choose direct reuse
versus adapted copy or approve a license plan; those decisions are separate
checklist items.

## Inventory

| Upstream area | Observed classes/interfaces and capability | HitHub relevance | Boundary or risk to verify |
| --- | --- | --- | --- |
| Git type contracts | `zif_abapgit_git_definitions`, `zif_abapgit_git_transport`, and `zif_abapgit_git_branch_list`. The definitions interface is self-contained and contains Git file, branch, object, commit, diff, SHA-1, and object-type structures. | Shared vocabulary for Steps 3–6 and 9. | The current contracts use fixed SHA-1 types such as `c LENGTH 40`; HitHub must keep algorithm-awareness in its own ports. |
| Object and pack codec | `zcl_abapgit_git_pack` exposes encode/decode operations for pack data and tree, commit, and tag payloads. Its implementation handles pack headers, object types, zlib data, object IDs, tree ordering, and pack trailers. | Strong candidate for Step 3 object codecs and Step 4 pack ingestion/emission. | The class combines codec, compression, hashing, progress reporting, and exception behavior. It must be isolated behind HitHub ports and checked for bounds/resource limits. |
| Delta processing | `zcl_abapgit_git_delta` exposes `decode_deltas` over Git objects and has dedicated delta-header parsing. | Step 4 `OFS_DELTA`/`REF_DELTA` work and property tests. | The upstream public API operates on abapGit object tables; thin-pack visibility, depth limits, overflow guards, and quarantine semantics are HitHub responsibilities. |
| Hashing and compression | `zcl_abapgit_hash` is listed in the Git package; `src/git/zlib` contains the custom zlib implementation used by `zcl_abapgit_git_pack`. Pack code calculates SHA-1 and Adler-32 and accepts more than one zlib header form. | Step 2 hashing/compression ports and Step 3–4 object/pack compatibility. | The implementation uses SAP kernel APIs and custom fallback logic. SAP/open-abap parity and limits need a dedicated spike and anomaly review. |
| Git transport and framing | `zcl_abapgit_git_transport` implements the abapGit client side of branch/commit upload-pack and receive-pack exchanges. `zcl_abapgit_git_utils` provides pkt-line string framing and UTF-8 length handling. `src/git/v2` is a separate protocol-v2 area. | Step 5 read-only Smart HTTP, Step 6 push, and packet-trace fixtures. | This is client transport code, not a server handler. It is useful for protocol behavior and interoperability references but cannot be assumed to supply server-side negotiation or visibility policy. |
| Commit and branch services | `zcl_abapgit_git_commit` retrieves and parses commit histories, resolves branch/commit pulls, sorts commits, and extracts author data. `zcl_abapgit_git_branch_list` and `zcl_abapgit_git_branch_utils` represent and process branches. | Steps 3, 5, 9, and repository browsing. | Methods are coupled to abapGit repository URLs and object-table structures; HitHub needs repository-scoped object-store ports and explicit ref transactions. |
| Repository lifecycle | `zcl_abapgit_repo`, `zcl_abapgit_repo_online`, `zcl_abapgit_repo_offline`, `zcl_abapgit_repo_srv`, checksums, content-list, stage/status, and filter subpackages coordinate local repository state and synchronization. | Step 2 repository adapters; Steps 7–10 application workflows and browsing. | These classes model SAP package/TADIR repositories and client synchronization, not HitHub repositories. Reuse is mainly a design/reference candidate until APIs are reviewed. |
| Diff and merge primitives | `src/diff` contains `zcl_abapgit_diff`, standard diff, a diff factory, and `zcl_abapgit_diff_diff3`; the latter exposes a three-way `compute` operation. | Step 9 changed-file, patch-summary, and three-way merge behavior; Step 8 diff rendering. | Text encoding, conflict representation, binary handling, and rename detection need HitHub-specific contracts and tests. |
| HTTP client adapter | `zcl_abapgit_http`, `zcl_abapgit_http_client`, and related HTTP/auth classes create SAP HTTP clients, set Smart HTTP headers, send binary payloads, validate content types/statuses, and support digest authentication. | Step 1 local/SAP HTTP seam and Steps 5–6 interoperability tests. | It is an outbound client adapter. HitHub’s inbound ICF/Express boundary must not depend on it, though its exact media types and error checks are useful references. |
| Persistence and test seams | `src/persist` contains persistence factories, injectors, migrations, database, repository, user, package, settings, and background persistence services. Many Git classes have ABAP Unit test classes beside them, including commit, delta, pack, transport, and utility tests. | Step 2 adapter contract tests and deterministic test doubles. | Persistence is shaped around abapGit settings and SAP package metadata; it is not a matching HitHub metadata schema. |

## Deliberately excluded from this Git-primitives inventory

The large `src/objects` tree primarily serializes SAP development objects to
abapGit repository files. It is relevant when HitHub hosts ABAP source
repositories, but it is not required to implement the Git object database or
Smart HTTP protocol. It will be revisited only if a later feature requires
ABAP-object-aware behavior.

## Capability observations

- The upstream project describes itself as a Git client for ABAP and lists
  abapGitServer among supported remote providers.
- The Git package contains explicit tests beside the commit, delta, pack,
  transport, and utility implementations, which makes those tests useful
  candidates for compatibility-fixture discovery.
- The transport implementation advertises and parses client capabilities such
  as `side-band-64k`, `no-progress`, `multi_ack`, `report-status`, and shallow
  depth in the inspected source. HitHub must publish its own supported
  capability matrix after server-side behavior is implemented.

## Follow-up review queue

1. Record the exact upstream revision for each selected candidate (Step 0).
2. Compare the pack/delta tests and fixtures with native Git golden vectors
   (Steps 3–4).
3. Review the protocol-v0/v1 and `src/git/v2` behavior before implementing
   server negotiation (Steps 5–6).
4. Identify any narrowly scoped abapGit API changes that would simplify an
   adapter, and record them in `SUGGESTIONS.md` before building a workaround.

Sources: [upstream source tree](https://github.com/abapGit/abapGit/tree/main/src),
[Git package](https://github.com/abapGit/abapGit/tree/main/src/git),
[pack codec](https://github.com/abapGit/abapGit/blob/main/src/git/zcl_abapgit_git_pack.clas.abap),
[delta decoder](https://github.com/abapGit/abapGit/blob/main/src/git/zcl_abapgit_git_delta.clas.abap),
[transport](https://github.com/abapGit/abapGit/blob/main/src/git/zcl_abapgit_git_transport.clas.abap),
[definitions](https://github.com/abapGit/abapGit/blob/main/src/git/zif_abapgit_git_definitions.intf.abap),
[diff package](https://github.com/abapGit/abapGit/tree/main/src/diff),
[HTTP client](https://github.com/abapGit/abapGit/blob/main/src/http/zcl_abapgit_http_client.clas.abap),
and [repository package](https://github.com/abapGit/abapGit/tree/main/src/repo).
