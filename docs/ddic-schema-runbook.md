# HitHub DDIC activation and schema-change runbook

## Install the artifact set

The checked-in DDIC source package is `src/persistence`. Import that directory
with the approved abapGit or transport workflow; do not create a second local
schema or hand-written migration. The package contains 15 tables:

`ZHI_REPOSITORY`, `ZHI_REFERENCE`, `ZHI_OBJECT`, `ZHI_EVENT`,
`ZHI_IDEMPOTENCY`, `ZHI_PULL_REQUEST`, `ZHI_PR_COMMENT`,
`ZHI_PR_LINE_CMNT`, `ZHI_PR_REVIEW`, `ZHI_PR_MERGE_RES`, `ZHI_ISSUE`,
`ZHI_ISSUE_CMNT`, `ZHI_ISSUE_ASGN`, `ZHI_ISSUE_LABEL`, and
`ZHI_REPO_LOCK`.

It also contains the shared `ZHI_DE_*` data elements for identifiers, ref
names, OIDs, text, payloads, timestamps and versions. Keep the imported
objects in the `ZHI_*` customer namespace and transport the executable ABAP
classes with the same release revision.

Lock object `EZHI_REPO` ships with the persistence artifacts and is defined
over `ZHI_REPO_LOCK-REPOSITORY_ID`. `ZHI_REPO_LOCK` never holds a row; it
exists so the lock argument is exactly the lock granularity. The lock argument
is the whole key of the root table, and SAP rejects one longer than 150
characters, so the data tables cannot serve: `ZHI_REFERENCE` keys on
`REPOSITORY_ID` and `REF_NAME` for 196 characters, and shortening `REF_NAME`
would truncate legitimate Git ref names. Activate the lock object with the
tables and confirm the generated function modules are `ENQUEUE_EZHI_REPO` and
`DEQUEUE_EZHI_REPO` with a `REPOSITORY_ID` parameter; `ZCL_HITHUB_SAP_ENQUEUE`
calls them under exactly those names for repository ref transactions.

Long text and byte columns use the `STRG` and `RSTR` data elements
`ZHI_DE_STRING` and `ZHI_DE_RAWSTRING`, so they are LOB columns with no
declared maximum. They are not key fields, the tables are unbuffered, and they
carry no `NOT NULL` flag, which is what LOB columns require: SAP refuses to
activate that flag on a column longer than 255. Do not convert them back to
`LCHR` or `LRAW`: those demand a preceding `INT2`/`INT4` length field and the
last position in the table, which the row layouts here do not provide.

`ZHI_ISSUE_LABEL` stores the label value in `LABEL_NAME`. `LABEL` is a
reserved word and DDIC rejects it as a field name.

Five tables activate with a "key length > 120 (restricted functions)" warning:
`ZHI_IDEMPOTENCY`, `ZHI_ISSUE_ASGN`, `ZHI_ISSUE_LABEL`, `ZHI_REFERENCE` and
`ZHI_REPOSITORY`. The warning is accepted, not overlooked: the key lengths are
what the Git and REST contracts require, and the restricted functions (table
maintenance generation among them) are not used. Review it again before adding
a key field to any of these.

## Change design

1. Describe the business field, owning aggregate, nullability, length,
   indexing and compatibility impact in the change record.
2. Prefer additive changes: new nullable columns, new tables, or new indexes.
   Do not rename or remove a field in the same release that introduces its
   replacement.
3. Update the checked-in ABAP DDIC artifact, persistence mapping, local schema
   verifier and relevant tests together. Keep the SAP and local definitions
   structurally identical.
4. Update the backup and restore manifests when a new durable table or payload
   column is introduced.

## SAP activation

1. Import the persistence artifact set and transport into a non-production
   system. Confirm the target
   SAP release supports every DDIC property.
2. Activate domains and data elements first, then tables, indexes, the lock
   object, and dependent
   persistence code. Resolve activation warnings explicitly.
3. Run the table consistency check and inspect generated database changes.
   Do not accept an implicit destructive conversion.
4. Exercise repository creation, ref compare-and-swap, issue/PR mutation,
   audit insertion, Git object persistence, and lock acquisition in the test
   system.
5. Promote through the approved transport path only after backup and restore
   owners sign off.

## Local verification

1. Run `npm run transpile` to rebuild the local database statements from the
   same ABAP artifacts.
2. Run `npm run schema`, `npm run unit`, `npm run contract`, and the relevant
   native Git suites.
3. Compare the verifier's table, column, type and primary-key output with the
   SAP activation result.
4. Keep generated output and local database files out of source control.

The local verifier must report the same 14 tables, columns, types and primary
keys as the SAP activation result. A mismatch is a release blocker; resolve
the artifact or activation transport rather than adding adapter-specific SQL.

## Rollback and compatibility

Take a consistent backup before activation. If activation or validation fails,
keep the service in maintenance mode and restore the pre-change backup or
apply the approved backward-compatible correction. Do not manually delete
columns or rows to force activation. Record the transport, schema verifier
output, test evidence, operator and final decision.
