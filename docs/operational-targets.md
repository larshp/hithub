# Initial concurrency and timeout targets

These targets apply per application-server instance unless the deployment
adapter provides a shared limiter. The configured defaults are exercised by
the `npm run load-soak` harness; deployment adapters must provide equivalent
limits when traffic is distributed across multiple instances.

| Target | Initial value | Policy |
| --- | ---: | --- |
| Total in-flight HTTP requests | 64 per instance | Excess requests receive a retryable overload response. |
| Concurrent expensive Git operations | 8 per instance | Applies to pack generation, pack ingestion, reachability walks, and merge computation. |
| Repository lock wait | 10 seconds | Fail the operation without changing refs when the lock cannot be acquired. |
| REST request timeout | 30 seconds | Includes repository metadata and read-only browsing APIs. |
| Smart HTTP discovery timeout | 10 seconds | Applies to `info/refs` requests. |
| Upload-pack request timeout | 5 minutes | Includes negotiation and streamed pack generation. |
| Receive-pack request timeout | 10 minutes | Includes streaming, validation, quarantine promotion, and ref commit. |
| Merge request timeout | 5 minutes | Includes final locked validation and object persistence. |

Timeouts cancel work at the port boundary and release locks/quarantine roots
through cleanup handlers. A timed-out or overloaded write operation must not
make a partial ref state visible. The values remain subject to revision when
production traffic or a later pack/delta performance spike justifies tuning.
