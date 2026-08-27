# Runtime spikes

## SAP Git-object spike

`spikes/sap/zhi_git_object_spike.prog.abap` is an executable SE38 report. It
calls abapGit’s `ZCL_ABAPGIT_GIT_TRANSPORT=>UPLOAD_PACK_BY_COMMIT` method and
prints the requested decoded object’s type, OID, and payload size.

Run it in a SAP system with the full abapGit installation at revision
`d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6`, then supply a repository URL and a
40-character commit OID. Record the SAP release, abapGit revision, URL-safe
fixture, output, and any discrepancy in the spike results before treating the
API as portable.

## open-abap Git-object spike

`spikes/open-abap/zhi_git_object_spike.prog.abap` invokes the same public API.
Its `abap_transpile.json` loads open-abap core and the required abapGit source
areas. Run from the repository root with:

```text
npx abap_transpile -c spikes/open-abap/abap_transpile.json
```

The abapGit library checkout must be pinned to
`d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6` for a compatibility comparison;
the transpiler configuration supplies the upstream URL, while the release
workflow is responsible for resolving and recording that immutable checkout.

## Adapted abapGitServer HTTP-flow spike

`spikes/sap/zcl_hi_ags_discovery_spike.clas.abap` and
`zhi_ags_http_spike.prog.abap` adapt the upstream `BRANCH_LIST` discovery flow:
service preamble, HEAD advertisement, capability list, ref packets, flush
packet, and response metadata. The flow uses abapGit’s pkt-line helper at the
boundary and is isolated from the future HitHub router. Run the report in SE38
after installing the pinned abapGit and abapGitServer prerequisites.
