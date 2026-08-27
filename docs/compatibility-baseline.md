# Compatibility baseline

## Minimum SAP release

HitHub supports SAP NetWeaver AS ABAP 7.52, with the applicable SAP kernel and
ICF support for the installation's support package level. Older SAP releases
are not part of the MVP support matrix.

This baseline is selected because it provides the language and HTTP runtime
capabilities needed by the planned application while remaining compatible with
the open-abap development runtime. The exact support-package level and kernel
requirements will be pinned in the installation documentation before release.

## ABAP language version

Production sources target the ABAP 7.52 language version (standard language
scope, without release-specific cloud restrictions). The local open-abap
configuration must reject syntax outside this target unless a compatibility
decision is recorded in the project documentation.

## ABAP object namespace

HitHub uses the customer namespace `ZHI_*` for global ABAP objects and DDIC
artifacts. The namespace is intentionally usable without a registered SAP
partner namespace; object names must still respect the naming limits of the
minimum supported release.

## Project license

HitHub is distributed under the MIT License. Reused or adapted upstream
components retain their original attribution and license notices in the
location required by those licenses.

## Native Git compatibility

The initial native-Git interoperability target is:

| Client | Supported version | Role |
| --- | --- | --- |
| Git for Windows | 2.32.0.windows.2 | Minimum local compatibility baseline |

The release matrix may add newer client versions after they have completed the
clone, fetch, push, and merge interoperability suites. Versions older than the
listed baseline are not supported by the MVP.

## abapGit compatibility

The initial abapGit interoperability target is:

| Client | Supported version | Role |
| --- | --- | --- |
| abapGit | v1.134.0 | Initial SAP/open-abap compatibility baseline |

This version is the latest upstream release recorded in the baseline on
2026-08-27. The release process must retest the supported abapGit version and
update this matrix before selecting a newer revision.

## GUI Git compatibility test target

The selected GUI client for the first compatibility test is GitHub Desktop
3.6.3 for Windows x64, the stable version listed in the official release notes
reviewed on 2026-08-27. This is a test target, not a claim that the MVP already
supports the client.

The test must configure an HTTPS remote by URL and exercise the same
repository through the GUI:

- clone an empty and a populated repository;
- fetch and refresh branches/tags after server-side changes;
- create a branch, commit, and push it;
- pull a fast-forward update and observe a rejected stale push;
- verify that binary pack responses and authentication failures surface as
  actionable errors rather than being treated as successful synchronization.

The target is appropriate because GitHub Desktop exposes a URL-based clone
flow and its documentation describes working with repositories hosted on
GitHub or other Git hosting services. The test must use the URL path rather
than GitHub-specific account or fork integration.
