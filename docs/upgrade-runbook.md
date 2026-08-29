# HitHub upgrade runbook

## Plan the change

1. Record the current HitHub revision, SAP/open-abap versions, DDIC schema
   revision, configured limits, and active deployment topology.
2. Read the release changelog and [compatibility baseline](compatibility.md).
   Confirm that the target SAP release, native Git clients, abapGit versions,
   and browser matrix remain supported.
3. Review `ANORMALIES.md`, `SUGGESTIONS.md`, and the release known limitations
   for changes that affect the deployment.
4. Schedule a maintenance window for schema or handler changes. Keep a
   rollback owner and restore system assigned.

## Back up and stage

1. Take and verify a consistent database/object-store backup using the
   [backup runbook](backup-runbook.md). Do not upgrade with receive-pack,
   merge, purge, or garbage-collection work active.
2. Import the target ABAP and persistence artifacts into a non-production SAP
   system or isolated local checkout. Keep the previous transport and backup
   immutable until acceptance.
3. Prefer additive DDIC changes. Follow the [DDIC activation
   runbook](ddic-schema-runbook.md); never use an ad-hoc SQL migration to make
   the local database resemble SAP.

## Deploy SAP

1. Activate the new DDIC objects and dependent classes in a test system, then
   run the schema, persistence, Git, REST, security, and lock checks.
2. For multiple application servers, drain one server at a time through the
   Web Dispatcher, activate the same transport, restart or reload it, and
   verify `/live`, `/ready`, authenticated Git discovery, and a read-only
   clone before returning it to rotation.
3. Repeat the drain, activation and checks for every server. Do not mix
   handler revisions or schema revisions across active nodes beyond the
   compatibility window recorded for the release.
4. Re-run the deployment-boundary checks for authentication, TLS, actor
   propagation, request limits, log redaction, and shared enqueue locking.

## Deploy local open-abap

From the new checkout, install the lockfile and rebuild the generated runtime:

```sh
npm ci
npm run transpile
npm run lint
npm run unit
npm run schema
npm run contract
npm run smoke
```

Run the native Git, resilience, restore, and browser checks appropriate to the
change. Keep the old generated output out of source control and do not reuse a
local database from an incompatible schema without restoring it through the
documented procedure.

## Validate and accept

1. Start the upgraded service in isolation and require `/live` and `/ready` to
   succeed.
2. Clone a release-critical repository, fetch a non-default ref, run
   `git fsck --strict`, and exercise representative REST issue, pull-request,
   audit, and ref reads.
3. Confirm metrics, correlation IDs, timeout/overload responses, backup age,
   and garbage-collection dry-run output are normal.
4. Obtain application, database/restore, and deployment-boundary sign-off
   before reopening writes or public traffic.

## Roll back

If activation, validation, or early monitoring fails, stop writes at the ICF
or gateway boundary. Drain the service, restore the pre-upgrade durable set
using the [restore runbook](restore-runbook.md), and reactivate the matching
previous DDIC/handler revision. Verify readiness, clone/integrity, and ref
state before reopening traffic. Record the failed revision, evidence, data
loss window, and follow-up action; do not repair refs manually.
