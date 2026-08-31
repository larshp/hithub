# Git protocol v2 advertisement

`ZCL_HITHUB_PROTOCOL_V2` can emit the initial v2 advertisement as pkt-lines:

- `version 2\n`
- `agent=hithub\n`
- `ls-refs\n`
- `fetch=shallow\n`
- flush pkt

The empty-repository path accepts the v2 `ls-refs` command and returns an empty
ref section. Non-empty v2 fetch behavior remains subject to repository and
pack-selection integration.
