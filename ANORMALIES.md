# open-abap and transpiler anomaly log

Keep resolved entries as compatibility history. Add an entry when a behavior
differs between SAP and open-abap/transpiler or its database adapter, before
adding a workaround. Ordinary defects that reproduce identically on both
runtimes do not belong here.

## Entry template

Copy this template for each anomaly. Replace every placeholder and remove this
instruction text from the completed entry.

### ANOMALY-YYYY-MM-DD-short-name — Short title

- Status: `open` | `workaround` | `reported` | `fixed` | `not-an-anomaly`
- Discovery date: `YYYY-MM-DD`
- Affected open-abap/transpiler/database-adapter versions: `...`
- Affected ABAP statement, runtime API or adapter: `...`
- Minimal ABAP reproducer: `path/to/reproducer`
- Exact command used to run it: `...`
- Expected SAP behavior: `...`
- Actual open-abap behavior: `...`
- Impact on HitHub: `...`
- Smallest safe workaround: `...` or `none`
- Upstream issue: `link` or explanation why it has not been reported
- Regression-test location: `path/to/test`
- Upstream version containing a fix: `...` or `unknown`
