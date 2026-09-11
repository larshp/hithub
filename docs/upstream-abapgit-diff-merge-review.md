# abapGit diff and merge review

Reviewed revision: `d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6` of
[abapGit](https://github.com/abapGit/abapGit), reviewed 2026-08-28. The
review identifies reusable algorithm boundaries; HitHub will keep its own
object store, merge policy, and failure semantics.

## Diff APIs

- `src/diff/zif_abapgit_diff.intf.abap` defines a byte-oriented diff factory
  boundary. It accepts old/new UTF-8 `xstring` values, supports ignoring
  indentation, comments, and case, and returns line changes plus statistics,
  beacons, and patch markers.
- `src/diff/zcl_abapgit_diff.clas.abap` selects the SAP
  `RS_CMP_COMPUTE_DELTA` implementation when available and falls back to
  `zcl_abapgit_diff_diff3=>compute`. It then calculates statistics and maps
  structural ABAP beacons, keeping the public result independent of the
  selected algorithm.
- `src/diff/diff3/zif_abapgit_diff3.intf.abap` exposes reusable line-array
  operations: LCS, comm-style differences, offset/length indices, patch,
  patch inversion/stripping, merge regions, and three merge renderings.
  `zcl_abapgit_diff3` returns explicit `ok` and `conflict` regions and can
  include base text and caller-supplied conflict labels.

## Tree merge APIs

- `src/repo/stage/zif_abapgit_merge.intf.abap` models source, target, common,
  and result expanded trees, a staging area, conflict records, and the
  selected source branch. Conflicts retain source/target blob IDs and bytes so
  a caller can resolve them explicitly.
- `src/repo/stage/zcl_abapgit_merge.clas.abap` fetches both branches, walks
  commit ancestors, selects a common ancestor, expands all three trees, and
  merges the union of path/name entries.
- Tree decisions are deterministic: unchanged-on-one-side takes the other
  side, equal additions are accepted, deletions are handled against the
  common tree, and changes on both sides become conflicts. Resolved blobs are
  staged through `zcl_abapgit_stage` and are not silently committed by the
  merge calculator.
- The accompanying diff3 test class exercises LCS, patch round trips,
  stable/unstable regions, normal merges, false-conflict suppression, and
  conflict output. These tests are useful seeds for HitHub domain tests.

## HitHub adaptation decisions

HitHub will place these capabilities behind ports for ancestor traversal,
tree expansion, blob loading, and text merging. Binary blobs will remain
conflicts unless a dedicated strategy is selected; all merge results will be
validated against immutable pull-request snapshots, repository locks, and
compare-and-swap ref updates. The SAP kernel diff optimization is optional and
must not change the documented result or conflict states.
