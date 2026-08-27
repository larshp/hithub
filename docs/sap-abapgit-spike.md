# SAP abapGit read-object spike

The SAP-only report at
[`spikes/sap/zhi_abapgit_read_spike.prog.abap`](../spikes/sap/zhi_abapgit_read_spike.prog.abap)
proves the first direct abapGit integration seam. It calls the public
`zcl_abapgit_git_commit=>get_by_commit` API from abapGit `v1.134.0` and checks
that at least one parsed commit object is returned.

## Prerequisites

- SAP NetWeaver AS ABAP 7.52 or later with outbound HTTPS/TLS configured.
- The full abapGit `v1.134.0` repository installed in the system, including
  `zcl_abapgit_git_commit`, `zif_abapgit_git_definitions`, and
  `zcx_abapgit_exception`.
- Network access to the selected Git Smart HTTP endpoint, or an equivalent
  reachable test repository.

The report is intentionally outside the production `/src` tree. It is a
runtime probe, not a production dependency or the final HitHub adapter.

## Run

Create or upload the report as `ZHI_ABAPGIT_READ_SPIKE`, then run it in SE38 or
ADT. The default parameters request the pinned abapGit release commit from
`https://github.com/abapGit/abapGit.git`:

```text
URL:    https://github.com/abapGit/abapGit.git
SHA-1:  b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f
Deepen: 0
```

For a private endpoint, replace the URL and provide the credentials required
by the SAP HTTP destination or abapGit configuration. Do not put credentials
in the report parameters or repository files.

## Pass criteria

The report must finish with `abapGit SAP read-object spike: PASS`, and the
requested SHA-1 must be found among the parsed objects and printed as the
returned SHA-1. A transport, TLS, authentication, malformed-response, or
missing-object error is a failed spike and should be recorded in
`ANORMALIES.md` only if the behavior differs from the later open-abap run.

The API call is the compatibility seam for the next checkbox: the open-abap
spike must invoke this same abapGit API with the same inputs and compare the
returned object fields.

Reference: [abapGit commit API](https://github.com/abapGit/abapGit/blob/v1.134.0/src/git/zcl_abapgit_git_commit.clas.abap)
and [pinned upstream revision](upstream-revisions.md).
