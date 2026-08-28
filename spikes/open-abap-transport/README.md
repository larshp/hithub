# abapGit transport fixture

This narrowed open-abap build loads the pinned abapGit Git transport and pack
implementation without importing unrelated SAP UI and factory classes. The
local proxy and login classes are deliberately no-op test adapters; the
transport, HTTP client, pkt-line exchange and pack decoder remain upstream
abapGit code.

Transpile it with:

```sh
npx abap_transpile spikes/open-abap-transport/abap_transpile.json
```

With the fixture server running on port 3000, run:

```sh
node scripts/run-abapgit-fixture.mjs
```
