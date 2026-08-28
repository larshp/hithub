# abapGit simplification suggestions

Record narrowly scoped changes that would improve abapGit independently of
HitHub. Add a suggestion before committing to a larger HitHub-specific
adapter or copied implementation. Keep a local fallback regardless of
upstream acceptance.

## Entry template

Copy this template for each suggestion. Replace every placeholder and remove
this instruction text from the completed entry.

### SUGGESTION-000 — Short title

- Status: `proposed` | `reported` | `accepted` | `implemented` | `declined` | `obsolete`
- Affected abapGit class, interface or component: `...`
- Reviewed upstream revision: `...`
- Current integration difficulty: `...`
- HitHub code complicated by this: `...`
- Smallest proposed refactoring or public API change: `...`
- Intended simpler ABAP usage:

  ```abap
  " Replace with a minimal example of the proposed API.
  ...
  ```

- Expected benefits for HitHub and other abapGit consumers: `...`
- HitHub fallback if not accepted upstream: `...`
- Upstream issue or pull request: `link` or `none`
- First abapGit version containing the change: `...` or `unknown`

## SUGGESTION-001 — Public Git object codec façade

- Status: `proposed`
- Affected abapGit class, interface or component: `src/git`, especially
  `ZCL_ABAPGIT_GIT_COMMIT`, `ZCL_ABAPGIT_GIT_TAG`, and Git definitions
- Reviewed upstream revision: `d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`
- Last reviewed: `2026-08-28`
- Current integration difficulty: consumers must depend on concrete classes
  and internal type definitions to parse or emit canonical Git objects.
- HitHub code complicated by this: the object-domain adapter would need to
  translate HitHub ports to several abapGit-specific concrete APIs.
- Smallest proposed refactoring or public API change: expose a small public
  interface for canonical commit/tag/tree/blob payload parsing and emission,
  with algorithm-aware object IDs represented independently of fixed SHA-1
  fields.
- Intended simpler ABAP usage:

  ```abap
  DATA(lo_codec) = zcl_abapgit_git_factory=>create_object_codec( ).
  DATA(ls_commit) = lo_codec->parse_commit( iv_payload = lv_payload ).
  ```

- Expected benefits for HitHub and other abapGit consumers: stable reuse,
  fewer dependencies on internal classes, easier testing, and a clearer seam
  for future hash algorithms.
- HitHub fallback if not accepted upstream: an adapter around the reviewed
  concrete classes, protected by native-Git golden fixtures.
- Upstream issue or pull request: `none`
- First abapGit version containing the change: `unknown`
- Review result: the pinned revision still exposes separate concrete commit
  parsing and tag-prefix helper APIs; no shared public object-codec façade is
  available, so this suggestion remains `proposed`.

## SUGGESTION-002 — Stream-oriented pack reader seam

- Status: `proposed`
- Affected abapGit class, interface or component: `ZCL_ABAPGIT_GIT_PACK`,
  `ZCL_ABAPGIT_GIT_DELTA`, and the `src/git/zlib` support
- Reviewed upstream revision: `d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`
- Last reviewed: `2026-08-28`
- Current integration difficulty: pack processing is exposed primarily as
  client-oriented operations, while callers with large repositories need
  bounded reads and an explicit base-object resolver.
- HitHub code complicated by this: the server pack adapter would otherwise
  buffer protocol input and couple quarantine validation to abapGit internals.
- Smallest proposed refactoring or public API change: add a public pack-reader
  interface accepting bounded chunks and a callback/resolver for repository-
  visible base objects, without changing existing client APIs.
- Intended simpler ABAP usage:

  ```abap
  DATA(lo_reader) = zcl_abapgit_git_factory=>create_pack_reader(
    io_base_resolver = lo_resolver ).
  lo_reader->read( io_input = lo_input ).
  ```

- Expected benefits for HitHub and other abapGit consumers: lower peak memory,
  reusable pack validation, explicit thin-pack behavior, and easier fuzzing.
- HitHub fallback if not accepted upstream: a local streaming parser behind
  the pack port, with the anomaly log used for runtime discrepancies.
- Upstream issue or pull request: `none`
- First abapGit version containing the change: `unknown`
- Review result: the pinned revision exposes whole-buffer pack encode/decode
  methods and table-based delta decoding, with no stream-oriented input or
  repository-visible resolver seam; this suggestion remains `proposed`.
