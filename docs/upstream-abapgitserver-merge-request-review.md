# abapGitServer merge-request review

Reviewed revision: `3808345145b4d0fa78c74cbabf4964383c1aa1ad` of
[larshp/abapGitServer](https://github.com/larshp/abapGitServer), reviewed
2026-08-28. The review records reusable behavior; HitHub keeps its own
pull-request contract, immutable snapshots, actor model, and merge policy.

## Reusable domain behavior

- Merge requests are between two branches in the same repository. The
  upstream README asks callers to push a new branch before adding commits so
  the server can observe the branch as a ref.
- Creation accepts a repository, title, source branch, and target branch. It
  rejects a source branch already merged into the target and rejects a second
  unmerged request for the same source/target pair.
- Creation allocates a repository-local numeric ID while holding the merge
  request enqueue lock, then persists repository, source/target branches,
  title, creator, and an unmerged flag.
- The service finds the first common commit while walking source and target
  histories. It walks source changes back to that ancestor and combines file
  entries by filename and path, retaining old and new blob IDs for added,
  modified, and deleted files.
- Detail responses expose the current source/target tips, ancestor, changed
  files, branch names, stored request fields, and the current runtime user.
  The upstream detail operation recalculates the commit comparison rather
  than storing immutable tip snapshots.
- Merge detection recognizes a request when a target history contains the
  source tip as either parent of a merge commit, and can associate merged
  requests while scanning commits between two target tips.

## Reusable ABAP source references

- The request DTOs, changed-file representation, and service operations are in
  `src/service/zcl_ags_service_rest.clas.abap`, especially the type section
  and `CREATE_MERGE_REQUEST`, `GET_ANCHESTOR_MERGE_REQUEST`, and
  `GET_MERGE_REQUEST` methods.
- Persistence and duplicate prevention are in
  `src/database/zcl_ags_db_merge_requests.clas.abap`; the repository-local ID
  allocation uses `ENQUEUE_EZAGS_MERGE_REQ`.
- History-based merged-request detection is in
  `src/backend/zcl_ags_merge_requests.clas.abap`, with fixture-backed tests in
  its `.testclasses.abap` companion.
- REST route metadata for create, detail, list, and ancestor operations is in
  the `GET_META` method of
  `src/service/zcl_ags_service_rest.clas.abap`. Service behavior tests for
  added, modified, and deleted files are in
  `src/service/zcl_ags_service_rest.clas.testclasses.abap`.
- The persistence shape is represented by `src/ddic/zags_merge_req.tabl.xml`:
  repository, numeric ID, title, source/target branches, merged flag, and
  creator.

## HitHub adaptation decisions

HitHub will preserve the same-repository source/target model and
repository-local uniqueness, but will add explicit `open`, `closed`, and
`merged` states, draft readiness, immutable base/head snapshots, review and
comment records, deterministic mergeability, and compare-and-swap merge
guards. These additions avoid treating a dynamically recomputed upstream
view as an auditable pull-request record.
