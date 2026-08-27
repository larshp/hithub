# Supported SAP application-server topology

The MVP supports SAP NetWeaver AS ABAP 7.52 SP04 or later in either of these
forms:

- a single application server with the standard SAP database and enqueue
  service; or
- multiple application servers behind SAP Web Dispatcher or an equivalent
  gateway, all using the same SAP database and enqueue service.

HitHub ICF handlers are request-stateless. Repository metadata and Git objects
are stored in shared SAP persistence, and repository ref transactions acquire
the shared enqueue/repository lock so a request routed to any application
server observes the same compare-and-swap state. Temporary quarantine data
must use storage visible to the worker that owns the request and must be
recoverable/cleanable after worker failure.

The MVP does not support application-server-local persistence, a load-balanced
deployment without shared locking, or active-active nodes with independently
managed databases. The local open-abap runtime is a separate single-process
development/test topology and is not a SAP scale-out target.
