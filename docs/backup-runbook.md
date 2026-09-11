# HitHub backup runbook

## Scope

Back up the complete durable HitHub database, including repository metadata,
references, Git objects, pull requests, issues, comments, labels, assignees,
merge results, idempotency records and audit events. A metadata-only backup is
not sufficient: refs without their objects cannot be cloned.

## Before the backup

1. Confirm the backup target, retention policy, encryption key and restore
   owner in the deployment change record.
2. Confirm the database and object store are healthy through `/ready` and the
   normal monitoring checks.
3. Schedule a consistent database snapshot. Do not copy individual DDIC tables
   or object files while ref transactions are in progress.
4. Record the snapshot timestamp, HitHub version, active schema revision and
   open anomaly entries.

## SAP procedure

Use the approved SAP database backup tooling and transport/change-management
process for the active system. The snapshot must include every `ZHI_*` table
and the storage containing Git object payloads. Preserve database encryption,
access controls and audit retention metadata. Store the backup outside the
application server and test that the backup can be read by the designated
restore system.

## Local procedure

Stop the local service or otherwise ensure no request is mutating the database,
then copy the configured SQLite database and any configured object-store
directory as one versioned backup set. Keep the generated files out of source
control. Encrypt the set before moving it to durable backup storage.

## Retention and monitoring

Keep daily, weekly and release-point backups according to the deployment
policy. Monitor snapshot completion, size changes, age of the newest good
backup, encryption-key availability and restore-test results. Treat a failed
or partial snapshot as unusable and alert the restore owner.

## Restore verification

1. Restore into an isolated SAP client/system or local test workspace; never
   overwrite production during verification.
2. Confirm all expected `ZHI_*` tables and object payloads are present.
3. Run the schema verifier and `git fsck --strict` corpus checks.
4. Clone every release-critical repository, fetch a second ref, and verify
   representative issue, pull-request, audit and reference records through
   REST.
5. Compare restored repository/ref/object counts with the snapshot manifest.
6. Record the restore duration, discrepancies and sign-off. Keep the restored
   verification environment isolated until cleanup is approved.

## Recovery decision

Restore the newest backup that passes integrity verification and predates the
incident. If the latest snapshot fails, continue backward through the retained
set and escalate the loss window. After recovery, rotate exposed credentials,
review audit events and schedule a follow-up backup/restore test.
