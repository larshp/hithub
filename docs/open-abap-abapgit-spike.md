# open-abap abapGit read-object spike

The open-abap probe at
[`spikes/open-abap/src/zhi_abapgit_open_read_spike.prog.abap`](../spikes/open-abap/src/zhi_abapgit_open_read_spike.prog.abap)
mirrors the SAP report at
[`spikes/sap/zhi_abapgit_read_spike.prog.abap`](../spikes/sap/zhi_abapgit_read_spike.prog.abap).
Both runtimes call the same public `zcl_abapgit_git_commit=>get_by_commit` API
with the same default repository and object ID. The open-abap report uses
constants because its transpiler does not support interactive selection-screen
parameters.

## Prepare and build

From the repository root on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File spikes/open-abap/prepare.ps1
abap_transpile.cmd spikes/open-abap/abap_transpile.json
```

The preparation script checks out abapGit `v1.134.0` and verifies the full
commit `b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f`. The transpiler obtains the
open-abap core as a build dependency and includes the minimal production
abapGit source slice needed by the API. Its setup hook initializes the generated
SQLite schema before the ABAP classes are imported; generated dependencies and
output remain ignored by Git.

## Run

Run the generated program with:

```powershell
node spikes/open-abap/run.mjs
```

The program uses the same defaults as the SAP probe: the abapGit Smart HTTP
repository URL, the pinned commit SHA-1, and deepen level `0`. It installs a
headless no-op progress implementation because GUI progress is not available in
Node. It must print
`abapGit open-abap read-object spike: PASS` and the requested SHA-1 as the
returned object. A transport, HTTP, protocol, parsing, or missing-object
failure is a failed open-abap probe.

The SAP report's parameters can be changed when testing an equivalent local Git
server. The open-abap constants can be changed for the same purpose. Credentials
must never be placed in the source or generated output.

This is a compatibility probe only. Production HitHub code will use its own
ports and will not depend on abapGit or native Git at runtime.
