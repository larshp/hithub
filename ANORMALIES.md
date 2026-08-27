# open-abap and transpiler anomaly log

This file records behavior that differs between SAP and the local open-abap
runtime, database adapter, or ABAP-to-JavaScript transpiler. Ordinary HitHub
defects that reproduce identically on both runtimes do not belong here.

Copy the template below for each anomaly. Resolved entries remain in this file
as compatibility history.

## Entry template

### ANO-000 — Short title

- Status: `open`
- Discovered: `YYYY-MM-DD`
- Affected versions: open-abap `x.y.z`; transpiler `x.y.z`; adapter `x.y.z`
- Affected statement/API/adapter: `<ABAP statement, runtime API, or adapter>`
- Minimal ABAP reproducer:

  ```abap
  " Replace with the smallest reproducer.
  ```

- Exact command: `<command used to run the reproducer>`
- Expected SAP behavior: `<behavior>`
- Actual open-abap behavior: `<behavior>`
- Impact on HitHub: `<impact>`
- Smallest safe workaround: `<workaround or none>`
- Upstream issue: `<link, or explain why it has not been reported>`
- Regression test: `<repository path>`
- Upstream version containing a fix: `<version, commit, or unknown>`
