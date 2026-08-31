# Compatibility baseline

## Minimum supported SAP release

HitHub supports SAP NetWeaver AS ABAP 7.52 SP04 and later SAP releases that
provide the same or a compatible ABAP runtime contract.

The release floor is chosen as the initial compatibility target for the
`IF_HTTP_EXTENSION` entry point and the ABAP language/runtime features needed
by the dual SAP/open-abap implementation. Any use of a newer SAP-only API must
be isolated behind an infrastructure adapter and documented as a later-release
requirement.

## Supported ABAP language version

HitHub targets the standard ABAP language version available on the minimum
supported release, SAP NetWeaver AS ABAP 7.52 SP04. ABAP for Cloud Development
is not the target language version because HitHub requires classic ICF and
on-premise persistence integration.

## ABAP object namespace

Persisted and executable ABAP objects use the customer namespace `ZHI_*`.
The namespace prefix is reserved for HitHub objects; the exact suffix is
assigned per object type and kept within the naming limits of the target SAP
release.

## Project license

HitHub is distributed under the MIT License. Reused or adapted upstream code
retains its original copyright and license notices alongside the applicable
HitHub attribution.

## Supported native Git versions

The initial native-client compatibility target is Git 2.30 and later. The
representative verification matrix is Git 2.30, Git 2.39 and Git 2.43; the
local development baseline is Git 2.43.0. Support means the documented
Smart-HTTP capability matrix passes for the client version; unsupported
protocol capabilities must not be advertised.

## Supported abapGit versions

The initial abapGit compatibility target is v1.131.0 through v1.134.0. The
range starts at the first version selected for the MVP baseline and includes
the current upstream release reviewed on 2026-08-27. Each supported version
must pass the captured HTTP interoperability suite; the exact revision used
for a release is recorded with that release artifact. The upstream version
history is maintained in the [abapGit changelog](https://github.com/abapGit/abapGit/blob/main/changelog.txt).

## Selected GUI Git client

The selected GUI compatibility client is Git GUI from the Git 2.43.0
distribution. It delegates clone, fetch, and push to native Git and supports
arbitrary HTTP remotes, keeping the GUI test focused on HitHub’s published
Git behavior. `git-gui` is not installed in the current headless development
environment; later GUI compatibility runs must install the client before
executing this test target.

## Supported browser UI baseline

The browser UI smoke matrix supports the current Playwright Chromium and
Firefox projects. The same suite runs against both browsers in CI; WebKit is
not in the current support baseline because its host-library requirements are
not part of the supported development and deployment environments.
