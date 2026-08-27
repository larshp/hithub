# Git component reuse strategy

The mapping below is the initial design decision for each planned Git-facing
component. A `direct call` entry is a candidate only: it must pass the SAP and
open-abap spikes before it is used in production. Every adapted or copied
component remains behind a HitHub port and is covered by native-Git fixtures.

The abapGitServer candidates below were reviewed at
`3808345145b4d0fa78c74cbabf4964383c1aa1ad`; the abapGit candidates were
reviewed at `d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`. These immutable
revisions are the source pins for the initial reuse review.

| HitHub component | Reuse mode | Upstream candidate | Boundary and local work |
| --- | --- | --- | --- |
| Object ID hashing | direct call candidate | abapGit `ZCL_ABAPGIT_HASH` | Wrap behind the hashing port; remove fixed SHA-1 assumptions from public types. |
| Commit and annotated-tag codecs | adapted copy candidate | abapGit `ZCL_ABAPGIT_GIT_COMMIT`, `ZCL_ABAPGIT_GIT_TAG` | Preserve canonical bytes while exposing HitHub algorithm-aware value objects. |
| Blob and tree codecs | inspiration | abapGit Git definitions and object/repository code | Implement HitHub codecs against explicit byte payload contracts. |
| Loose-object headers | new implementation | Git object format, verified against abapGit/native Git | Keep header generation pure and independently tested. |
| Loose-object compression | direct call candidate | abapGit `src/git/zlib` | Call only through the compression port; provide an open-abap substitute if required. |
| Pack and delta decoding | adapted copy candidate | abapGit `ZCL_ABAPGIT_GIT_PACK`, `ZCL_ABAPGIT_GIT_DELTA` | Add streaming input, limits, repository-visible base resolution, and quarantine semantics. |
| Pack indexing and emission | inspiration | abapGit pack implementation | Implement server-specific indexing/streaming with explicit resource limits. |
| Object reachability walks | inspiration | abapGit repository/status abstractions | Build a repository-scoped graph service that cannot cross object-store boundaries. |
| Ref-name validation | direct call candidate | abapGit branch utilities and Git definitions | Wrap and extend with server policy checks and algorithm-aware OIDs. |
| Pkt-line codec | adapted copy candidate | abapGit Git transport parser/utilities | Make framing binary-safe, streaming, and independent of client-only transport flow. |
| Upload-pack discovery and negotiation | adapted copy candidate | abapGitServer Git service; abapGit transport behavior | Retain only protocol behavior covered by HitHub capability tests. |
| Receive-pack parsing and status | adapted copy candidate | abapGitServer Git service; abapGit transport report-status parser | Add multi-ref commands, quarantine validation, CAS, locks, and side-band output. |
| Smart HTTP ICF entry point | adapted copy candidate | abapGitServer service and SICF classes | Adapt to HitHub routing and request-context ports; preserve binary bodies. |
| REST routing and serialization | inspiration | abapGitServer REST service | Implement HitHub’s application-service contracts, problem details, ETags, and idempotency. |
| Repository metadata persistence | inspiration | abapGitServer database/DDIC areas | Implement HitHub schema, repository-scoped constraints, soft deletion, and transactions. |
| Ref transactions and locking | new implementation | Git compare-and-swap rules; upstream behavior as reference | Must satisfy HitHub lock, quarantine, audit, and failure-recovery requirements. |
| Diff and merge primitives | inspiration | abapGit diff/merge utilities when identified | Implement explicit three-way merge contracts and deterministic mergeability states. |
| Repository browser UI | inspiration | abapGitServer frontend | Build the HitHub web shell and accessibility/security policy independently. |

No external Git executable is selected for production behavior. Native Git is
used only as the interoperability oracle in tests.
