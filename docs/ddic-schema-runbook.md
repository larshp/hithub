# HitHub DDIC activation and schema-change runbook

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

1. Import the transport into a non-production system and confirm the target
   SAP release supports every DDIC property.
2. Activate domains and data elements first, then tables, indexes and dependent
   persistence code. Resolve activation warnings explicitly.
3. Run the table consistency check and inspect generated database changes.
   Do not accept an implicit destructive conversion.
4. Exercise repository creation, ref compare-and-swap, issue/PR mutation,
   audit insertion and Git object persistence in the test system.
5. Promote through the approved transport path only after backup and restore
   owners sign off.

## Local verification

1. Run `npm run transpile` to rebuild the local database statements from the
   same ABAP artifacts.
2. Run `npm run schema`, `npm run unit`, `npm run contract`, and the relevant
   native Git suites.
3. Compare the verifier's table, column, type and primary-key output with the
   SAP activation result.
4. Keep generated build output and local database files out of source control.

## Rollback and compatibility

Take a consistent backup before activation. If activation or validation fails,
keep the service in maintenance mode and restore the pre-change backup or
apply the approved backward-compatible correction. Do not manually delete
columns or rows to force activation. Record the transport, schema verifier
output, test evidence, operator and final decision.
