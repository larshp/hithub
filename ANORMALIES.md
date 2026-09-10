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

## Open anomalies

### ANOMALY-2026-09-10-xstring-hex-case — Character to byte conversion keeps the source text

- Status: `open`
- Discovery date: `2026-09-10`
- Affected open-abap/transpiler/database-adapter versions: `@abaplint/runtime 2.13.83`
- Affected ABAP statement, runtime API or adapter: assignment and `CONV` between
  `string` and `xstring`
- Minimal ABAP reproducer: `src/core/zcl_hithub_tree_codec.clas.testclasses.abap`,
  method `converts_lower_case_hex`
- Exact command used to run it: `npm run unit`
- Expected SAP behavior: `string` to `xstring` interprets the source as
  hexadecimal digits, and `xstring` to `string` renders upper case hex, so
  `CONV xstring( 'ab' )` and `CONV xstring( 'AB' )` are the same byte.
- Actual open-abap behavior: `XString.set` stores the character string verbatim.
  Case is preserved on the way back, and text that is not hex at all is accepted
  (`CONV xstring( 'blob fixture' )` in
  `src/core/zcl_hithub_blob_codec.clas.testclasses.abap` does not raise).
- Impact on HitHub: object ids are lower case hex. Tree entries hold them as raw
  bytes, and `zcl_hithub_contents_service`, `zcl_hithub_file_editor`,
  `zcl_hithub_compare_service` and `zcl_hithub_reachability` turn those bytes
  back into a string to address the child object. On the transpiler the case
  survives, on SAP it does not, which is the suspected cause of the browsing and
  editing failures seen in the SWF_ABAP_UNIT run of 2026-09-10.
  `zcl_hithub_reachability=>walk` already carries a `TRANSLATE ... TO LOWER CASE`
  for exactly this reason.
- Smallest safe workaround: normalise with `TRANSLATE ... TO LOWER CASE` after
  every byte to string conversion of an oid, as `zcl_hithub_reachability` does.
- Upstream issue: not reported yet, pending confirmation of the SAP side by the
  probes listed below.
- Regression-test location: `src/core/zcl_hithub_tree_codec.clas.testclasses.abap`
- Upstream version containing a fix: `unknown`

Covering methods in that include: `converts_lower_case_hex`,
`keeps_oid_case_round_trip` and `separates_trees_by_entry_oid`.
