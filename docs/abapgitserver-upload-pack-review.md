# abapGitServer upload-pack review

Reviewed revision: [`3808345145b4d0fa78c74cbabf4964383c1aa1ad`](https://github.com/larshp/abapGitServer/tree/3808345145b4d0fa78c74cbabf4964383c1aa1ad)

The review covers the pinned [`ZCL_AGS_SERVICE_GIT`](https://github.com/larshp/abapGitServer/blob/3808345145b4d0fa78c74cbabf4964383c1aa1ad/src/service/zcl_ags_service_git.clas.abap)
implementation and the client-side request/response behavior in
abapGit's pinned [`ZCL_ABAPGIT_GIT_TRANSPORT`](https://github.com/abapGit/abapGit/blob/d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6/src/git/zcl_abapgit_git_transport.clas.abap).

## Server flow

`ZCL_AGS_SERVICE_GIT->RUN` stores the ICF server reference, then selects the
operation from the request: an empty body invokes discovery, a path containing
`git-upload-pack` invokes pack generation, and a path containing
`git-receive-pack` invokes push handling.

Upload-pack discovery (`BRANCH_LIST`) currently:

- resolves the repository name from the `~path` header;
- loads the repository HEAD and branches through `ZCL_AGS_REPO`;
- advertises `multi_ack`, `no-thin`, `side-band`, `side-band-64k`, `shallow`,
  `no-progress`, `include-tag`, `report-status`, `multi_ack_detailed`,
  `no-done`, `symref=HEAD:refs/heads/master`, and
  `agent=git/abapGitServer`;
- emits the service preamble, HEAD packet with NUL-separated capabilities,
  branch packets, and a flush packet; and
- sets `Server: abapGitServer`, `Cache-Control: no-cache`, and
  `application/x-git-<service>-advertisement`.

Pack generation (`PACK`) currently:

1. Decodes `want`, `have`, capability, and `deepen` lines from the raw request.
2. Selects an ACK mode from `multi_ack` or `multi_ack_detailed`.
3. Emits `NAK` or ACK packets through `ZCL_AGS_XSTREAM`; the detailed mode can
   send an intermediate response and receive another request.
4. Loads every requested commit with `ZCL_AGS_OBJ_COMMIT`.
5. Expands reachable objects with `ZCL_AGS_PACK=>EXPLODE`, sorts and removes
   duplicate `(type, sha1)` pairs, then encodes with `ZCL_AGS_PACK=>ENCODE`.
6. Splits the pack into 8196-byte chunks, wraps each chunk in side-band 1,
   appends a flush packet, and returns
   `application/x-git-upload-pack-result`.

## Reusable behavior

| Upstream behavior | HitHub treatment |
| --- | --- |
| Service/branch discovery packet order and media types | Adapt behind a HitHub discovery response builder and exact pkt-line tests |
| Capability advertisement shape | Start with a documented v0/v1 allow-list; advertise only capabilities implemented by HitHub |
| `want`/`have`/`deepen` request fields | Reuse the data model, but replace the permissive line parser with bounded binary pkt-line decoding |
| ACK mode selection and NAK/ACK sequencing | Adapt as a stateless negotiation service with explicit request and response state |
| Reachability expansion and duplicate elimination | Reuse the concept with HitHub object-store reads, repository visibility, and resource limits |
| Side-band 1 pack framing and final flush | Preserve the wire behavior behind a streaming pack-output port |
| `ZCL_AGS_XSTREAM` and `ZCL_AGS_REPO` | Do not reuse directly; both bind protocol output and repository state to upstream classes |

The abapGit transport confirms the peer contract: discovery is requested at
`/info/refs?service=git-upload-pack`; the first `want` carries capabilities,
subsequent wants omit them, optional `deepen` precedes a flush, and the client
sends `done`. Its parser keeps only side-band 1 data before passing the pack to
`ZCL_ABAPGIT_GIT_PACK=>DECODE`.

## HitHub boundaries and gaps

HitHub should keep repository lookup, ref visibility, negotiation state,
object reachability, pack limits, and response streaming in separate ports.
The upstream flow currently relies on assertions for malformed protocol input,
materializes the complete pack before sending it, exposes a fixed
`master` symref, and does not provide HitHub's repository-scoped authorization,
bounded request handling, or protocol-v2 policy. Those are adaptation points,
not behavior to copy unchanged.

The next implementation checkbox is therefore the pkt-line encoder. The
discovery builder can then be tested against the recorded packet order before
the upload-pack router is connected to repository services.
