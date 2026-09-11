# HitHub restore runbook

## Declare and isolate

1. Declare the incident, assign a recovery lead and record the target recovery
   point and acceptable data-loss window.
2. Prevent writes to the affected service at the SAP ICF/gateway boundary. Do
   not begin a restore while Git receive-pack, merge, purge or garbage
   collection work is active.
3. Provision an isolated restore system/client or local workspace with the
   same compatible SAP/open-abap and HitHub versions.

## Select and restore

1. Select the newest encrypted backup whose manifest and checksum are valid.
2. Restore the database and Git object store as one consistent backup set.
3. Restore encryption configuration and access controls without copying
   production secrets into an operator workstation.
4. Activate the matching DDIC artifacts and run the schema verifier. Stop if
   activation changes the expected schema or any required `ZHI_*` table is
   missing.

## Validate before cutover

1. Start the isolated service and require `/ready` to succeed.
2. Run `npm run schema` where applicable and `git fsck --strict` against the
   restored repository corpus.
3. Clone each release-critical repository, fetch a non-default ref, and
   compare refs and object IDs with the backup manifest.
4. Query representative repository, issue, pull-request, comment and audit
   records through REST. Confirm actor and correlation fields remain intact.
5. Run the security, limits, contract and native interoperability suites.
6. Record counts, missing objects, failed requests and validation timestamps.

## Cutover and rollback

1. Obtain recovery-owner and application-owner sign-off on the isolated
   validation results.
2. Place the production service in maintenance mode, take a final incident
   snapshot if possible, and replace the durable set using the approved SAP
   database/object-store procedure.
3. Start the service, verify `/live` and `/ready`, then perform read-only clone
   and REST checks before reopening writes.
4. Monitor errors, latency, ref updates and audit events during the recovery
   window. Keep the old durable set unchanged until the recovery is accepted.
5. If validation or early monitoring fails, close writes and roll back to the
   prior durable set; never repair refs by hand without recording the change.

## Closeout

Record the restored backup ID, recovered timestamp, validation evidence,
remaining loss window, credential rotations, operator sign-off and the date of
the next restore rehearsal.
