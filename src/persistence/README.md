# DDIC artifacts

The initial metadata schema is represented as abapGit table artifacts:

- `ZHI_REPOSITORY` stores repository identity and optimistic version state.
- `ZHI_REFERENCE` stores repository-scoped refs and algorithm-aware OIDs.
- `ZHI_OBJECT` stores immutable Git object identity and payload data.
- `ZHI_EVENT` stores sanitized audit events.
- `ZHI_PULL_REQUEST` stores pull-request state and write-once base/head tips.
- `ZHI_PR_COMMENT` stores immutable pull-request discussion comments.
- `ZHI_PR_LINE_CMNT` stores immutable commit/path/line discussion comments.
- `ZHI_PR_REVIEW` stores immutable approval and change-request reviews.
- `ZHI_PR_MERGE_RES` stores immutable merge results for retry responses.
- `ZHI_IDEMPOTENCY` stores actor-scoped request idempotency keys.
- `ZHI_ISSUE` stores issue lifecycle state.
- `ZHI_ISSUE_CMNT` stores issue discussion comments.
- `ZHI_ISSUE_ASGN` stores free-form issue assignee labels.
- `ZHI_ISSUE_LABEL` stores issue labels in field `LABEL_NAME`; `LABEL` is a
  reserved word and cannot be used as a DDIC field name.
- `ZHI_REPO_LOCK` carries no rows. It is the root table of the `EZHI_REPO`
  lock object, so that the lock argument is exactly `REPOSITORY_ID`.

The 15 table artifacts and 13 shared data elements are additive and
activation-safe. Field-level checks, unique normalized repository-name
enforcement, payload storage limits, and adapter mapping are verified by the
persistence contract tests. SAP also requires the `EZHI_REPO` lock object;
see the [DDIC activation runbook](../../docs/ddic-schema-runbook.md).
