# Git Smart HTTP capability policy

The initial v0/v1 advertisement is deliberately limited to capabilities whose
server behavior is already available:

| Capability | Status | Reason |
| --- | --- | --- |
| `no-thin` | advertised | Incoming pack handling requires repository-visible bases; thin-pack support is not exposed yet |
| `no-progress` | advertised | HitHub does not emit progress side-band messages |
| `symref=HEAD:<ref>` | advertised when a default branch exists | The repository service supplies the actual HEAD target |
| `agent=hithub` | advertised | Identifies the HitHub server implementation |
| `multi_ack`, `multi_ack_detailed` | not advertised yet | ACK negotiation is not implemented yet |
| `side-band`, `side-band-64k` | not advertised yet | Side-band response streaming is a later checkbox |
| `shallow` | not advertised yet | Shallow negotiation is a later checkbox |
| `include-tag`, `no-done` | not advertised yet | Their upload-pack semantics are not implemented yet |

Receive-pack discovery advertises `report-status`, `side-band-64k`, `no-thin`,
`delete-refs`, `ofs-delta`, `object-format=sha1`, and `agent=hithub`. These
tokens are maintained separately from upload-pack capabilities because the
client request and response contracts differ.

The allow-list is implemented by
[`ZCL_HITHUB_GIT_CAPABILITIES`](../src/core/zcl_hithub_git_capabilities.clas.abap)
and will be consumed by the discovery response builder. Capability text is
rendered separately from pkt-line framing so binary transport code cannot
silently change the advertised values.
