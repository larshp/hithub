# abapGitServer browser review

Reviewed revision: `3808345145b4d0fa78c74cbabf4964383c1aa1ad` of
[larshp/abapGitServer](https://github.com/larshp/abapGitServer), reviewed
2026-08-28. The review is inspiration only; HitHub keeps its own API,
security model, and repository representation.

## Reusable browser flows

- Repository landing page: load the repository list, render each repository
  as a tile with its description, show its branches, and expose the clone URL
  and create-repository action.
- Repository dashboard: choose a branch, then navigate to its file tree or
  commit history.
- Tree browsing: preserve the repository, branch, and path in the URL; render
  directories as links, files as blob links, and the last commit as a
  secondary link.
- Blob/history navigation: open a blob from a tree row, offer raw content and
  history, and link history entries to commit details.
- Comparison flow: select source and target branches, show changed files, and
  navigate from each changed file to the corresponding blob or commit.

## Source patterns to retain as design input

- `src/frontend/02b363142b451ed68df0b5608910d699.smim.script.js:90-149`
  centralizes browser REST calls for repositories, branches, trees, commits,
  blobs, history, and merge requests. HitHub should retain the single client
  boundary, but use `fetch`, typed JSON, problem responses, and safe URL
  encoding.
- The same file at `:1090-1135` uses a compact repository tile with branch
  links, clone URL, loading state, and create link. HitHub will translate this
  into semantic HTML and keyboard-accessible controls.
- The same file at `:1150-1203` keeps tree path state separate from route
  state and distinguishes directory and file links. This is a useful flow
  for the planned tree browser, with repository-provided names escaped before
  rendering.
- `src/service/zcl_ags_service_rest.clas.abap:85-157` exposes separate
  application operations for repository creation, branch listing, file
  listing, commit listing, blob reads, commit reads, and history. HitHub will
  keep those responsibilities in explicit read-only application services
  rather than copying the upstream service class.

## HitHub adaptation decisions

The browser will consume the documented HitHub REST contract and Git Smart
HTTP routes. It will not depend on upstream field names such as `REPO.NAME`,
will not render raw HTML from repository content, and will keep merge-request
and write actions outside the read-only web-experience checkbox.
