# Upstream license and attribution review

Review date: 2026-08-27

This review covers every upstream candidate selected in the reuse map and
revision record. It is an engineering attribution record, not a legal opinion.
No upstream source or fixture has been copied into HitHub yet.

## Findings

| Candidate | Reviewed snapshot | License finding | Attribution action before copying |
| --- | --- | --- | --- |
| AG-GIT-1 | abapGit `v1.134.0`, `b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f` | MIT. The repository-level `REUSE.toml` assigns MIT to `**`; its explicit exceptions are Font Awesome icons, AJSON, and String-Map. The selected `src/git`, `src/diff`, and related HTTP paths are not among those exceptions. | Preserve the abapGit MIT copyright and permission notice in HitHub’s third-party notices, and record the source paths, tag, and full commit. Keep any copied file header unless a mechanical adaptation makes a header inapplicable. |
| AGS-SERVER-1 | abapGitServer `main`, `3808345145b4d0fa78c74cbabf4964383c1aa1ad` | MIT for the repository. The selected ABAP service, backend, database, DDIC, test, and performance material therefore has the same permissive baseline for adaptation or reference. | Preserve the abapGitServer MIT copyright and permission notice, and record the source paths and full commit. Do not imply that HitHub is the upstream project or that upstream maintainers endorse it. |

## Exclusions and transitive notices

- The abapGit exceptions for Font Awesome, AJSON, and String-Map are not part
  of the selected Git/diff reuse paths. Their code or assets must not be copied
  without a separate notice review.
- abapGitServer’s README lists frontend dependencies including React
  (Facebook BSD + Patents), jsdiff (BSD-3-Clause), wasm-git (GPL with linking
  exception), and several MIT packages. They are not selected HitHub reuse
  candidates, and HitHub will not copy those bundled assets as part of the
  current server-core plan. If a frontend asset is later copied, its exact
  version, license text, and required notices must be added before promotion.
- ABAP-Swagger, abapGit, and `abap_db_preparator` are recorded upstream
  requirements or test dependencies, not selected source candidates. Their
  licenses are therefore not being treated as licenses for HitHub code.

## Required repository practice

Before the first adapted upstream source or fixture is committed:

1. Add a `THIRD-PARTY-NOTICES.md` entry naming the upstream project, license,
   source path, tag/branch, and full commit from
   [upstream-revisions.md](upstream-revisions.md).
2. Include the complete applicable MIT notice, including the copyright and
   permission text; do not replace it with a bare URL.
3. Mark substantial adaptations in the copied source or adjacent provenance
   record, while keeping the upstream attribution visible.
4. Re-run this review whenever a selected revision changes or a new fixture,
   frontend asset, or dependency is introduced.

The project-level [LICENSE](../LICENSE) is also MIT, so the selected upstream
MIT terms are compatible with the current distribution license. This does not
remove the obligation to preserve upstream notices.

## Evidence

- [abapGit LICENSE at v1.134.0](https://github.com/abapGit/abapGit/blob/v1.134.0/LICENSE)
- [abapGit REUSE metadata](https://github.com/abapGit/abapGit/blob/main/REUSE.toml)
- [abapGit repository and credits](https://github.com/abapGit/abapGit)
- [abapGitServer repository and MIT classification](https://github.com/larshp/abapGitServer)
- [abapGitServer README and external-library license list](https://github.com/larshp/abapGitServer/blob/main/README.md)
- [Recorded immutable revisions](upstream-revisions.md)
