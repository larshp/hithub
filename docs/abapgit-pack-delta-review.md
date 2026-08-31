# abapGit pack and delta review

Reviewed revision: [`d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`](https://github.com/abapGit/abapGit/tree/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6)

The review covers the upstream [`zcl_abapgit_git_pack`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_pack.clas.abap) and [`zcl_abapgit_git_delta`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_delta.clas.abap) implementations.

## Reusable APIs

- Pack decoding validates the `PACK` signature, version 2, object count,
  per-entry type/size headers, zlib streams, object checksums and the final
  pack SHA-1. Its public `decode` method also delegates REF/OFS delta
  resolution after reading the entries.
- Pack encoding exposes `encode`, `encode_tree`, `encode_commit` and
  `encode_tag`; private helpers cover Git type/length varints and tree sorting.
- The pack object model is a flat list containing object type, raw data, object
  ID and pack index. REF deltas retain a base object ID until resolution.
- Delta decoding is table-oriented: `decode_deltas` repeatedly resolves delta
  entries against available bases and applies copy/insert instructions to the
  base bytes.

## HitHub boundary and changes

HitHub will adapt the parsing algorithms behind explicit pack and delta ports.
The upstream flat list becomes repository-scoped object records, with the
algorithm and repository ID carried alongside each object ID. The implementation
must add bounds checks, maximum pack/object/delta-depth limits, checksum
verification before publication, and quarantine semantics so a failed pack
cannot update the live object store or refs. Upstream zlib calls remain behind
`zif_hithub_compression`; native Git is used only as a test oracle.

The tree, commit and tag codecs already have independent HitHub contracts and
will be used by pack tests rather than copied into the pack parser.
