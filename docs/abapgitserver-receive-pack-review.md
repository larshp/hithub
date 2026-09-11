# abapGitServer receive-pack review

Reviewed revision: [`3808345145b4d0fa78c74cbabf4964383c1aa1ad`](https://github.com/larshp/abapGitServer/tree/3808345145b4d0fa78c74cbabf4964383c1aa1ad)

The review covers [`ZCL_AGS_SERVICE_GIT`](https://github.com/larshp/abapGitServer/blob/3808345145b4d0fa78c74cbabf4964383c1aa1ad/src/service/zcl_ags_service_git.clas.abap), especially its `receive-pack` path.

## Reusable flow

`ZIF_AGS_SERVICE~RUN` selects the operation from the request body and path:

1. An empty body calls `BRANCH_LIST`, which emits Smart HTTP discovery.
2. An upload-pack body calls `PACK`, decodes wants/haves, negotiates ACK/NAK, and streams a pack in side-band channel 1.
3. A receive-pack body calls `UNPACK`.

`UNPACK` uses four small seams that are useful to HitHub:

- `DECODE_PUSH` reads the first pkt-line length and extracts the fixed-width old OID, new OID, and ref name from the NUL-terminated command.
- The remaining body is separated at `0000` and passed to the pack decoder.
- The old/new OID pair selects create, delete, or update behavior.
- `UNPACK_OK` emits report-status messages (`unpack ok`, `ok <ref>`) in side-band channel 1, followed by the channel flush and stream flush.

The upload-pack side uses `FIND_ACK_MODE`, `NEGOTIATE_PACKFILE`, and an
`XSTREAM` response abstraction. Its `APPEND_BAND01` helper demonstrates the
useful server-side pattern: append bounded side-band chunks and terminate the
pkt-line stream with `0000`.

## HitHub reuse and ownership

HitHub should reuse the protocol shape and the separation between command
decoding, negotiation, pack handling, and report-status rendering. The
corresponding HitHub seams are:

| abapGitServer seam | HitHub treatment |
| --- | --- |
| `DECODE_PUSH` | Adapt into a validated receive-command parser; support multiple commands and algorithm-aware OIDs. |
| `NEGOTIATE_PACKFILE` | Reuse the ACK/NAK decision structure, with explicit v0/v1 capability validation. |
| `APPEND_BAND01` / `XSTREAM` | Reuse the side-band framing and connect it to the streaming response port. |
| `UNPACK_OK` | Adapt to capability-aware report-status and per-command results. |
| Repository branch mutation | Keep behind HitHub ref transactions and compare-and-swap. |

The following behavior is deliberately HitHub-owned and must not be copied as
is: quarantine and complete-pack validation, object-size and request limits,
fast-forward and ref-name policy, branch protection, repository locking,
multi-command atomicity, audit events, and cleanup after abandoned requests.
The upstream implementation also uses assertions for malformed or stale
state and mutates repository objects directly; those are unsuitable as the
HTTP boundary contract for HitHub.

## Implementation consequences

The receive-pack implementation should be built around this order:

```text
parse all commands
  -> validate refs, old OIDs, capabilities and limits
  -> decode and validate the complete pack in quarantine
  -> acquire repository lock
  -> recheck old OIDs and fast-forward/protection rules
  -> promote objects
  -> commit all refs atomically
  -> emit report-status and audit event
```

This keeps the useful upstream protocol behavior while preserving HitHub's
safe-reference-update decision and its SAP/local adapter boundary.
