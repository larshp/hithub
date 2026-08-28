# HitHub threat model

Status: baseline for the MVP; review before each release.

## Scope and assets

The protected assets are repository metadata, Git objects and refs, issue and
pull-request records, audit events, and deployment credentials. The browser,
Git clients, REST clients, Node/Express adapter, ABAP application services,
database, filesystem/object store, SAP ICF and any upstream gateway are in
scope.

## Trust boundaries

1. Clients cross the HTTP boundary and are untrusted. Request bodies, paths,
   refs, object IDs, identities and concurrency headers are validated.
2. The Node adapter and SAP ICF adapter cross into ABAP. Adapters provide
   transport and persistence only; ABAP owns repository rules and state
   transitions.
3. The deployment boundary supplies authentication, TLS and coarse service
   access. HitHub does not provide a user directory or repository roles.
4. The database/object store is the durable boundary. Ref updates use
   compare-and-swap, locks, transactions, quarantine and reachability checks.

## Threats and controls

| Threat | Control | Disposition |
| --- | --- | --- |
| Unauthorized service access | SAP ICF or gateway authentication is required for deployment; all admitted callers share the configured capability set. | Accepted MVP deployment responsibility; SAP ICF/gateway access review is required before production. |
| Credential or repository-content leakage | Structured logs contain operational metadata only; request bodies, authorization headers and Git payloads are excluded. | Closed for the HitHub service; gateway and SAP log review remains a deployment acceptance step. |
| Cross-site request forgery | Cookie-authenticated mutations require matching CSRF cookie and header; CORS is explicit. | Closed locally; accepted deployment responsibility for equivalent SAP ICF/gateway policy. |
| XSS in repository content | UI uses `textContent` and safe markdown rendering; CSP disallows inline scripts and objects. | Closed by the security regression suite. |
| Path/ref injection | Route patterns, ref validators, object-ID validators and repository-name validation constrain inputs. | Closed by route, REST, security and native-Git regression coverage. |
| Resource exhaustion | Request-body limits, pack byte/object limits, rate limits, operation deadlines and Git-operation admission control are enforced. | Closed for configured bounds; load-based tuning is accepted as post-MVP operational work. |
| Lost or conflicting metadata updates | Mutable metadata uses optimistic versions; ref and merge operations use locks and compare-and-swap. | Closed in the local contract suite; SAP scale-out verification is an accepted deployment gate documented in `docs/sap-locking-test.md`. |
| Malformed or malicious Git data | Packet, pack, delta, decompression, object-size, reachability and hash checks run before ref visibility. | Closed for the maintained corpus and regression suite; broader fuzzing is accepted as ongoing hardening. |
| SSRF through repository features | The MVP has no outbound URL fetch or remote repository import capability. | Accepted MVP limitation; reassess before adding integrations. |
| Audit tampering | Audit events are persisted in the same database and exposed read-only through the API/UI. | Accepted MVP limitation; external append-only export is optional operational hardening. |

## Accepted MVP limitations

Fine-grained authorization, collaborators, invitations, SSH, Git LFS,
outbound integrations and CI runners are outside this threat model. The
deployment owner remains responsible for TLS, authentication, network policy,
backups and SAP application-server hardening.

## Verification evidence

Run `npm run security`, `npm run limits`, `npm run logging`, `npm run timeout`,
`npm run backpressure`, the REST/UI contract suites, and the native Git tests.
Repeat SAP ICF access, logging, authorization and lock-failure checks against
the target deployment before production use.
