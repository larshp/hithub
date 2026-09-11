# Third-party attribution and license review

This file records the license obligations for upstream components considered
for the MVP. It must be updated when a candidate changes from inspiration to
direct or adapted reuse.

| Upstream component | Reviewed revision | License | Required attribution |
| --- | --- | --- | --- |
| [abapGitServer](https://github.com/larshp/abapGitServer) | `3808345145b4d0fa78c74cbabf4964383c1aa1ad` | MIT | Preserve the upstream MIT notice, including `Copyright (c) 2015 Lars Hvam`, in any adapted or copied substantial portion. |
| [abapGit](https://github.com/abapGit/abapGit) | `d01dc3e80dc9f04bb5cf26322ff0a14f97ecc8d6` | MIT | Preserve the upstream MIT notice, including `Copyright (c) 2014 abapGit Contributors`, in any adapted or copied substantial portion. |

The upstream license files were reviewed on 2026-08-27. The current mapping
uses some projects as inspiration only; inspiration does not copy code and
does not create a notice obligation. Any future direct call or adapted copy
must retain the applicable notice in the source distribution and update this
file if additional copyright holders or bundled dependencies are involved.

No abapGitServer frontend dependency is selected for reuse at this stage. Its
README lists separate third-party assets and licenses; those require a
component-level review before any asset or source is imported.
