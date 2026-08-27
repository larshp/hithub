# Initial resource limits

These are the Step 0 targets for the MVP. They are hard safety ceilings by
default and may be lowered by an administrator; increasing them requires a
review against SAP memory, request-time, storage, and backup capacity.

| Resource | Initial maximum | Definition |
| --- | ---: | --- |
| Repository logical Git data | 10 GiB | Sum of uncompressed reachable and retained Git object payloads in one repository, excluding metadata tables. |
| Single uncompressed Git object | 100 MiB | Blob, tree, commit, or tag payload after decompression and before storage. |
| Incoming push request | 500 MiB | Complete HTTP request body for one `git-receive-pack`, including pkt-lines and pack data. |
| Incoming pack decompressed data | 2 GiB | Total decompressed pack/object payload processed before promotion. |
| Delta-chain depth | 50 | Maximum base/delta links resolved for one object. |

The request-body ceiling is enforced before or during streaming ingestion, and
the object/pack ceilings are enforced before quarantine promotion. A rejected
operation must not update refs. The selected values are provisional until the
Step 0 performance spike measures the minimum supported SAP release and the
local runtime.
