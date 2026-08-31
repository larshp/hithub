# abapGit object implementation review

Reviewed revision: [`d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`](https://github.com/abapGit/abapGit/tree/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6)

The object implementation is organized under `src/git`. The following
components are relevant to HitHub:

| abapGit component | Reusable behavior | HitHub treatment |
| --- | --- | --- |
| [`zcl_abapgit_git_transport`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_transport.clas.abap) | Upload-pack transport orchestration | Compatibility reference only; use captured fixtures and native-Git tests unless a dedicated client adapter is introduced |
| [`zcl_abapgit_git_pack`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_pack.clas.abap) | Pack header, entry and object handling | Adapted copy only if the required stream/resource-limit seam cannot be injected |
| [`zcl_abapgit_git_delta`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_delta.clas.abap) | OFS/REF delta application and delta instruction handling | Adapted copy with explicit bounds and delta-depth checks |
| [`zcl_abapgit_git_commit`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_commit.clas.abap) | Commit record parsing and serialization | Inspiration for HitHub value objects and validation tests |
| [`zcl_abapgit_git_tag`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_tag.clas.abap) | Annotated-tag record representation | Inspiration; HitHub owns the public codec contract |
| [`zcl_abapgit_hash`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_hash.clas.abap) | Hash calculation and Git object-ID support | Reference implementation; call through the HitHub hashing port |
| [`zcl_abapgit_git_utils`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_utils.clas.abap) | Shared Git encoding and transport helpers | Inspiration and selective adapted helpers after tests establish the required contract |

## Boundary decisions

HitHub object codecs must not depend on HTTP, repository metadata tables or a
specific database. The HitHub core owns canonical object headers, OID
validation, immutable object values and malformed-input errors. abapGit remains
the compatibility reference and may supply adapted implementation code where
its behavior matches those contracts.

Pack and delta code will be evaluated separately in Step 4. That separation
keeps object-format correctness tests independent from streaming and resource
limits. Every adapted section must retain the MIT attribution recorded in
[`docs/attributions.md`](attributions.md).
