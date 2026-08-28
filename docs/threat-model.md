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

| Threat | Control | Residual risk / follow-up |
| --- | --- | --- |
| Unauthorized service access | SAP ICF or gateway authentication is required for deployment; all admitted callers share the configured capability set. | Deployment configuration must be reviewed and tested. |
| Credential or repository-content leakage | Structured logs contain operational metadata only; request bodies, authorization headers and Git payloads are excluded. | Verify gateway and SAP logs separately. |
| Cross-site request forgery | Cookie-authenticated mutations require matching CSRF cookie and header; CORS is explicit. | SAP deployments need equivalent gateway/ICF policy. |
| XSS in repository content | UI uses `textContent` and safe markdown rendering; CSP disallows inline scripts and objects. | Continue security regression testing. |
| Path/ref injection | Route patterns, ref validators, object-ID validators and repository-name validation constrain inputs. | Review new routes and Git capabilities. |
| Resource exhaustion | Request-body limits, pack byte/object limits, rate limits, operation deadlines and Git-operation admission control are enforced. | Tune limits under load. |
| Lost or conflicting metadata updates | Mutable metadata uses optimistic versions; ref and merge operations use locks and compare-and-swap. | Exercise multi-server SAP locking. |
| Malformed or malicious Git data | Packet, pack, delta, decompression, object-size, reachability and hash checks run before ref visibility. | Continue corpus and fuzz testing. |
| SSRF through repository features | The MVP has no outbound URL fetch or remote repository import capability. | Reassess before adding integrations. |
| Audit tampering | Audit events are persisted in the same database and exposed read-only through the API/UI. | Add external append-only export if required operationally. |

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
