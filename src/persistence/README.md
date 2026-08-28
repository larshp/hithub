# DDIC artifacts

The initial metadata schema is represented as abapGit table artifacts:

- `ZHI_REPOSITORY` stores repository identity and optimistic version state.
- `ZHI_REFERENCE` stores repository-scoped refs and algorithm-aware OIDs.
- `ZHI_OBJECT` stores immutable Git object identity and payload data.
- `ZHI_EVENT` stores sanitized audit events.
- `ZHI_PULL_REQUEST` stores pull-request state and write-once base/head tips.
- `ZHI_PR_COMMENT` stores immutable pull-request discussion comments.
- `ZHI_PR_LINE_COMMENT` stores immutable commit/path/line discussion comments.
- `ZHI_PR_REVIEW` stores immutable approval and change-request reviews.
- `ZHI_PR_MERGE_RESULT` stores immutable merge results for retry responses.

The artifacts are additive and activation-safe. Field-level checks, unique
normalized repository-name enforcement, payload storage limits, and adapter
mapping are verified by the persistence contract tests in the next checkboxes.
