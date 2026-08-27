# Upstream reuse revisions

Revision record date: 2026-08-27

This record satisfies the Step 0 revision checkbox. Each revision is immutable
and is the source snapshot for the candidates named in the inventories and
reuse map. License/attribution verification is recorded in
[upstream-license-review.md](upstream-license-review.md).

## Selected candidates

| Candidate | Repository and revision | Full commit | Selected paths/capabilities | Evidence and resolution |
| --- | --- | --- | --- | --- |
| AG-GIT-1 | [abapGit `v1.134.0`](https://github.com/abapGit/abapGit/releases/tag/v1.134.0) | `b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f` | `src/git` object definitions, pack/delta, hash, zlib, transport, branch/commit helpers, and `src/diff` used by the adapted-copy/inspiration/direct-call rows in [the reuse map](git-reuse-map.md) | The upstream tag page identifies `v1.134.0` and its commit; `git ls-remote` independently resolved the full tag SHA. |
| AGS-SERVER-1 | [abapGitServer `main`](https://github.com/larshp/abapGitServer/tree/main) | `3808345145b4d0fa78c74cbabf4964383c1aa1ad` | `src/service`, `src/backend`, `src/database`, `src/ddic`, `src/frontend`, and their tests/performance programs recorded as server-flow, persistence, and UI inspiration in [the abapGitServer inventory](upstream-abapgitserver-inventory.md) | `git ls-remote` resolved `refs/heads/main`; no upstream release tag was selected. |

## Resolution command

The full SHAs above were resolved from the public remote on 2026-08-27 with:

```text
git ls-remote https://github.com/larshp/abapGitServer.git refs/heads/main refs/tags/*
git ls-remote https://github.com/abapGit/abapGit.git refs/tags/v1.134.0
```

The recorded values were:

```text
3808345145b4d0fa78c74cbabf4964383c1aa1ad  refs/heads/main
b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f  refs/tags/v1.134.0
```

## Scope notes

- All abapGit paths in the reuse map use AG-GIT-1. A future upgrade must add a
  new row and re-run the compatibility suite before changing that reference.
- The abapGitServer inventory’s ABAP-Swagger and `abap_db_preparator` mentions
  are dependency/testing observations, not selected reuse candidates, so no
  revision is recorded for them in this checkbox.
- A branch or tag moving later does not alter this record; consumers must use
  the full commit when reproducing the review.
