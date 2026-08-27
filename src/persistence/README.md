# DDIC artifacts

The initial metadata schema is represented as abapGit table artifacts:

- `ZHI_REPOSITORY` stores repository identity and optimistic version state.
- `ZHI_REFERENCE` stores repository-scoped refs and algorithm-aware OIDs.
- `ZHI_OBJECT` stores immutable Git object identity and payload data.
- `ZHI_EVENT` stores sanitized audit events.

The artifacts are additive and activation-safe. Field-level checks, unique
normalized repository-name enforcement, payload storage limits, and adapter
mapping are verified by the persistence contract tests in the next checkboxes.
