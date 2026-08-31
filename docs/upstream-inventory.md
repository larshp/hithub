# Upstream reuse inventory

This inventory records candidates reviewed for the initial HitHub design. It
does not grant permission to copy code or establish a dependency by itself;
the selected revision, reuse mode, and attribution obligations are recorded
before implementation.

## abapGitServer

- Repository: [larshp/abapGitServer](https://github.com/larshp/abapGitServer)
- Reviewed revision: `3808345145b4d0fa78c74cbabf4964383c1aa1ad` (upstream
  `main`), reviewed 2026-08-27
- Project description: Git server implemented in ABAP; upstream README states
  that it is installed through abapGit and activated as the `ZABAPGITSERVER`
  ICF service.
- Candidate source areas:
  - `src/service/zcl_ags_service_git`: Smart HTTP service entry point and Git
    request/response handling.
  - `src/service/zcl_ags_service_rest`: REST service routing and serialization
    patterns.
  - `src/service/zcl_ags_service_static`: static asset serving through ICF.
  - `src/service/zcl_ags_sicf`: ICF request integration.
  - `src/backend`: repository and Git-domain behavior.
  - `src/database`: repository/object persistence implementation.
  - `src/ddic`: DDIC table and metadata artifacts.
  - `src/frontend`: repository browser and administration UI flows.
  - `src/service/zcl_ags_service_git.clas.testclasses.abap` and
    `zcl_ags_service_rest.clas.testclasses.abap`: upstream service tests and
    compatibility references.
- Relevant documented behavior: Smart HTTP clone/pull/push, repository
  browsing/creation, tags, and merge requests between branches of one repo.
- Initial HitHub use: inspect the service boundary, persistence mapping,
  request framing, and merge-request behavior before choosing direct reuse,
  adapted copy, inspiration, or new implementation.
- Known boundary: HitHub needs repository-scoped metadata, quarantine and
  compare-and-swap ref transactions, open-abap adapters, and a larger REST/UI
  contract than the upstream project documents; no direct reuse is assumed.
- License: upstream repository advertises MIT; verify file-level notices and
  attribution before selecting code.

## abapGit

- Repository: [abapGit/abapGit](https://github.com/abapGit/abapGit)
- Reviewed revision: `d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6` (upstream
  `main`), reviewed 2026-08-27
- Project role: ABAP Git client with reusable Git codecs, transport, hashing,
  compression, repository abstractions, and test fixtures.
- Candidate source areas:
  - `src/git/zcl_abapgit_git_commit`: commit representation and parsing.
  - `src/git/zcl_abapgit_git_tag`: annotated-tag representation and parsing.
  - `src/git/zcl_abapgit_git_pack` and `src/git/zcl_abapgit_git_delta`: pack
    and delta processing.
  - `src/git/zcl_abapgit_hash`: object hashing.
  - `src/git/zlib`: zlib compression support.
  - `src/git/zcl_abapgit_git_utils` and
    `src/git/zif_abapgit_git_definitions`: Git utility types and format rules.
  - `src/git/zcl_abapgit_git_transport`: Smart HTTP upload/receive-pack
    client flow and report-status parsing.
  - `src/repo/zcl_abapgit_repo*` and `src/repo/zif_abapgit_repo*`: repository,
    content, status, and listener abstractions.
  - `src/http/zcl_abapgit_http*`: SAP HTTP client boundary and binary response
    handling.
  - The corresponding `testclasses` files: executable behavior references and
    golden-test candidates.
- Initial HitHub use: reuse or adapt pure Git primitives after verifying their
  contracts against native Git; isolate SAP HTTP client and abapGit repository
  persistence behind HitHub ports.
- Known boundary: abapGit is primarily a client and ABAP development-object
  serializer, not a repository hosting application. Its repository services,
  persistence, authentication assumptions, and client-oriented transport
  signatures cannot be adopted as HitHub server contracts without adapters.
- License: upstream package metadata advertises MIT; retain upstream notices
  for adapted code.
