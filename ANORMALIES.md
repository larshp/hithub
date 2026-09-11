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

- Status: `fixed`
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
- Impact on HitHub: object ids are lower case hex. Tree entries and pack entries
  hold them as raw bytes, and `zcl_hithub_contents_service`,
  `zcl_hithub_file_editor`, `zcl_hithub_compare_service`,
  `zcl_hithub_repo_representation`, `zcl_hithub_pack_codec` and
  `zcl_hithub_reachability` turn those bytes back into a string to address the
  child object. The transpiler preserved the case, SAP does not, which caused
  the browsing, editing and compare failures in the SWF_ABAP_UNIT run of
  2026-09-10. `zcl_hithub_reachability=>walk` already carried a
  `TRANSLATE ... TO LOWER CASE` for exactly this reason.
- Smallest safe workaround: `zcl_hithub_object_id=>to_bytes( )` and
  `=>from_bytes( )`, used by every oid to byte conversion. `to_bytes( )` folds
  the id up before the conversion, `from_bytes( )` folds the result back down.
- Upstream issue: fixed in `@abaplint/runtime` 2.13.84, which reads a leading
  run of upper case hex digits and stops at the first other character. Seeded
  fixtures must write payload hex in upper case too, see `server/index.mjs`.
- Regression-test location: `src/core/zcl_hithub_object_id.clas.testclasses.abap`
- Upstream version containing a fix: `2.13.84`

Covering methods: `packs_and_unpacks_oids` in the include above, plus
`keeps_oid_case_round_trip` and `separates_trees_by_entry_oid` in
`src/core/zcl_hithub_tree_codec.clas.testclasses.abap`.
