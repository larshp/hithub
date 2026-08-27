# Git component reuse map

This map records the planned implementation mode for the Git-related
components in Steps 3–6 and 9–10 of `PLAN.md`.

The four modes mean:

- `direct call`: invoke an upstream public API from a narrow HitHub adapter;
- `adapted copy`: copy the algorithm with required attribution and change its
  surrounding contract or safety behavior;
- `inspiration`: use the upstream design, tests, or fixtures while writing a
  HitHub-specific implementation;
- `new implementation`: no upstream implementation is a suitable behavioral
  match, so HitHub owns the implementation.

The map is a strategy decision, not a license approval. Exact selected
revisions are recorded in [upstream-revisions.md](upstream-revisions.md), and
the license/attribution review is recorded in
[upstream-license-review.md](upstream-license-review.md); runtime spikes
remain later Step 0 deliverables.

## Component map

| Plan component(s) | Mode | Upstream evidence | Decision and boundary |
| --- | --- | --- | --- |
| Blob/tree/commit/tag codecs; canonical object headers; object-ID calculation | `adapted copy` | [`zcl_abapgit_git_pack`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_pack.clas.abap) | Reuse the proven byte-format algorithms and golden-test shape, but extract them behind HitHub’s algorithm-aware object-codec port. Do not retain the pack class’s fixed SHA-1/public type coupling. |
| Object-ID validation; commit identity/timestamp/parent parsing; tree modes and canonical ordering | `adapted copy` | [`zif_abapgit_git_definitions`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zif_abapgit_git_definitions.intf.abap) and [`zcl_abapgit_git_pack`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_pack.clas.abap) | Adapt the parsing rules and tests, adding strict validation and algorithm-length checks. HitHub’s public contracts must not expose only `ty_sha1`. |
| SHA-1 and Adler-32 primitives | `direct call` | [`zcl_abapgit_hash`](https://github.com/abapGit/abapGit/tree/v1.134.0/src/git) | Call the upstream hash API only through a HitHub hashing-port adapter. The SAP/open-abap spike must prove identical bytes and error behavior; otherwise switch the adapter to a local implementation without changing the core port. |
| Loose-object compression/decompression and zlib fallback | `adapted copy` | [`src/git/zlib`](https://github.com/abapGit/abapGit/tree/v1.134.0/src/git/zlib) and pack codec usage | Adapt the self-contained compression behavior behind the compression port. Add bounded output, explicit consumed-byte reporting, and anomaly regression coverage rather than exposing SAP kernel calls in core code. |
| Immutable object-store reads/writes; object deduplication; reachability walking | `new implementation` | The abapGit inventory identifies client repository persistence, not a repository-scoped immutable object store. | Implement for HitHub’s content-addressed repository model, transaction boundary, and quarantine semantics. Use abapGit object structures only as fixture inspiration. |
| Git ref-name validation; reference reads; compare-and-swap versions | `new implementation` | No matching public abapGit server/ref-transaction component was identified in the reviewed Git package. | Implement with HitHub’s repository/ref ports, including symbolic refs, stale-version errors, and algorithm-aware OIDs. |
| Pack header/object/trailer parsing and emission; base-object emission | `adapted copy` | [`zcl_abapgit_git_pack`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_pack.clas.abap) | Adapt the pack-format algorithms and existing tests into streaming-friendly reader/writer services. Add HitHub limits and checksum validation at the port boundary. |
| `OFS_DELTA` and `REF_DELTA` decoding | `adapted copy` | [`zcl_abapgit_git_delta`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_delta.clas.abap) | Adapt the delta algorithm, adding bounds checks, repository-visible base resolution, chain-depth limits, and overflow guards. Do not import the upstream object-table assumptions as the storage API. |
| Pack indexing; streaming pack input/output | `new implementation` | The reviewed abapGit Git package exposes pack encode/decode but no HitHub-compatible index or streaming store contract. | Implement the index and stream interfaces around HitHub storage and request lifecycles. Reuse pack corpus and checksum vectors where compatible. |
| Pack limits: compressed bytes, object count/size, delta depth, arithmetic overflow | `inspiration` | Existing pack/delta code and the recorded [`SUG-003`](../SUGGESTIONS.md) proposal | Define HitHub’s resource policy independently, then use upstream parsing behavior as a test/reference baseline. The local policy must fail before promotion. |
| Native Git and abapGit pack corpora; malformed-object/pack/property tests | `inspiration` | Git-class test companions in the [upstream Git package](https://github.com/abapGit/abapGit/tree/v1.134.0/src/git) | Build HitHub-owned fixtures with provenance and redacted packet traces. Import upstream vectors only after format and license review. |
| Pkt-line encoding/decoding; flush, delimiter, and response-end handling | `adapted copy` | [`zcl_abapgit_git_utils`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_utils.clas.abap) and [`SUG-001`](../SUGGESTIONS.md) | Adapt framing behavior into a binary-safe HitHub codec with explicit packet kinds and length limits. Preserve upstream text helper behavior only inside an adapter or compatibility test. |
| Protocol v0/v1 capabilities; want/have; ACK/NAK; shallow negotiation | `inspiration` | [`zcl_abapgit_git_transport`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_transport.clas.abap) | Use client request construction and parsing as interoperability evidence, but implement server negotiation as a HitHub state machine with repository visibility and resource policy. |
| Upload-pack discovery headers/service preamble; upload-pack routing; side-band pack output | `inspiration` | abapGit transport’s Smart HTTP headers and pack response handling; [upstream HTTP client](https://github.com/abapGit/abapGit/blob/v1.134.0/src/http/zcl_abapgit_http_client.clas.abap) | Implement inbound ICF/Express handlers in HitHub. Reuse media-type and packet fixtures as references; do not depend on abapGit’s outbound SAP HTTP client. |
| Pack response streaming and advertised-ref visibility filtering | `new implementation` | No client-side upstream component owns HitHub repository visibility or server response streaming. | Implement in the application/HTTP boundary with binary-safe streams and explicit visibility policy. |
| Protocol v2 capability advertisement, `ls-refs`, and `fetch` | `inspiration` | `src/git/v2` in the [upstream Git package](https://github.com/abapGit/abapGit/tree/v1.134.0/src/git) | Use the client implementation and Git specification as references, but keep v2 server state and capability policy separate from v0/v1. |
| Receive-pack command parsing; report-status; receive-pack side-band | `inspiration` | [`zcl_abapgit_git_transport`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_transport.clas.abap) | Reuse client wire examples and test vectors. Implement the server command validator and report lifecycle in HitHub because stale-ref and multi-ref rules are product policy. |
| Quarantine; complete-pack validation; promotion; abandoned-quarantine cleanup | `new implementation` | No matching abapGit client component. | Implement with HitHub object-store transactions and recovery rules; no object or ref becomes visible before validation and promotion succeed. |
| Fast-forward checks; updated ref names/target types; branch protection; push-size limits; stale old-OID rejection; repository lock | `new implementation` | No matching abapGit client component; the upstream transport only supplies the client’s old/new command shape. | Implement as one HitHub receive-pack policy/transaction service under the repository lock. |
| Optional trusted actor label and push audit event | `new implementation` | Not a Git primitive in abapGit. | Implement in HitHub request context and event ports; never infer trust from an unconfigured client header. |
| Commit history parsing, branch lookup, and graph traversal | `adapted copy` | [`zcl_abapgit_git_commit`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_commit.clas.abap) and branch classes in the [Git package](https://github.com/abapGit/abapGit/tree/v1.134.0/src/git) | Adapt parsing and deterministic ordering where useful. Replace URL/client retrieval with HitHub object-store and ref ports. |
| Merge-base and ahead/behind counting | `inspiration` | abapGit commit and repository graph services | Implement against HitHub’s immutable commit graph and missing-object errors; preserve deterministic traversal and add concurrent-ref tests. |
| Changed-file calculation and patch summaries | `adapted copy` | [abapGit diff package](https://github.com/abapGit/abapGit/tree/v1.134.0/src/diff) and repository content-list services | Adapt diff input/output to HitHub trees and blobs. Keep binary and oversized-file policy in HitHub’s application layer. |
| Three-way tree merge and three-way text-blob merge | `inspiration` | [`zcl_abapgit_diff_diff3`](https://github.com/abapGit/abapGit/blob/v1.134.0/src/diff/zcl_abapgit_diff_diff3.clas.abap) | Use the diff3 algorithm and conflict tests as references, then implement a HitHub merge result with explicit conflict paths and Git tree semantics. |
| Rename detection capability flag | `new implementation` | No required upstream behavior identified; the plan explicitly defers it. | Keep rename detection disabled behind a capability flag and do not let heuristics affect merge correctness. |
| Pull-request snapshots, transitions, comments, reviews, mergeability, and target policy | `new implementation` | abapGit repository services are client synchronization services, not HitHub pull requests. | Implement the domain state machine and policy service in HitHub metadata/application layers. |
| Merge-commit formatting and author/committer identity validation | `adapted copy` | [`zcl_abapgit_git_pack` commit encoder](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_pack.clas.abap) and [`zcl_abapgit_git_time`](https://github.com/abapGit/abapGit/tree/v1.134.0/src/git) | Adapt canonical commit formatting and timestamp rules, but enforce HitHub identity policy and expected-head checks in new application code. |
| Merge lock/recheck, object persistence, target-ref CAS, PR state/idempotent result/events | `new implementation` | No matching upstream server transaction workflow. | Implement the full compare-and-swap and recovery workflow in HitHub; upstream code can only supply object-format fixtures. |
| Merge button, conflict explanations, source deletion, squash merge, rebase merge | `new implementation` | No matching upstream Git client capability. | Implement in HitHub application/UI and expose separately testable merge strategies. |

## Non-mappings

The `src/objects` SAP serializer tree, abapGit UI, user settings, and SAP
package/TADIR lifecycle are not selected for HitHub’s Git core. They remain
possible inspiration for a future ABAP-source-specific feature but are not
required by the MVP Git server.

## Verification gates before implementation

1. Pin the exact upstream revision for each adapted/direct candidate.
2. Verify MIT attribution and any transitive license obligations before copying
   code or fixtures.
3. Run the SAP and open-abap object/hash/compression spikes.
4. Add native Git byte/ID fixtures before changing adapted codecs.
5. Revisit this map if a spike disproves a direct call or an upstream API
   changes.
