# MVP feature matrix

This is the scope baseline for the first production-worthy release. A feature
is MVP only when its corresponding checklist completion checks pass in CI.

| Area | MVP capability | Delivery channel | Acceptance evidence |
| --- | --- | --- | --- |
| Runtime | SAP ICF execution and local open-abap execution of the same ABAP behavior | SAP ICF, Node.js shim | Health, lint, transpile, unit, and HTTP smoke checks |
| Repositories | Create, retrieve, list, update, soft-delete, and administer repositories without a built-in user directory | REST, web UI | REST contracts and UI end-to-end tests |
| Git transport | Stateless Smart HTTP v0/v1 clone, fetch, push, branch and tag updates | Native Git, abapGit | Native Git and abapGit interoperability matrix; packet traces |
| Git data | Blob, tree, commit, annotated tag, loose objects, pack files, deltas, reachability, refs | REST, web UI, Git transport | Native Git byte/golden fixtures, malformed-input and `git fsck --strict` tests |
| Repository browsing | Branches, tags, commits, trees, blobs, raw files, comparisons, and unified/split diffs | Web UI, REST | Fixture repository browsing and comparison tests |
| Pull requests | Open/closed/merged states, drafts, reviews, comments, mergeability, and safe merge commits | REST, web UI | Domain, concurrency, merge, and native Git fetch tests |
| Issues | Issue lifecycle, comments, free-form actor labels, labels, and shared timeline | REST, web UI | Equivalent UI/REST workflow tests and deterministic timelines |
| Security boundary | Whole-service protection supplied by SAP ICF or an upstream gateway | Deployment configuration | Deployment/access documentation and security tests |
| Operations | Logs, correlation IDs, metrics, health/readiness, limits, backup/restore, and garbage collection | Runtime/admin docs | Threat, resilience, load/restore, and injected-failure tests |

## Explicit non-goals for the MVP

The release does not include a built-in user directory, collaborators,
invitations, repository roles, packages, Pages, wikis, projects, Sponsors,
organizations, federation, Git LFS, SSH transport, or Dumb HTTP. CI runners,
protocol-v2 completeness, forks, releases, webhooks, search, blame, archives,
imports, native object-storage adapters, and SHA-256 repositories remain
post-MVP backlog items unless a separately approved scope change promotes one.

## Compatibility baseline

- Native Git: 2.30 and later; representative verification targets 2.30, 2.39,
  and 2.43.
- abapGit: v1.131.0 through v1.134.0.
- Selected GUI client: Git GUI from the Git 2.43.0 distribution.
- Runtime and namespace decisions: [compatibility baseline](compatibility.md).
