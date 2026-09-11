# Persistence adapters

The local and SAP repository adapters intentionally share the same Open SQL
implementation. The local runtime supplies an SQLite connection to the ABAP
runtime, while SAP supplies its normal Open SQL connection and activated DDIC
tables. The explicit SAP classes are deployment-facing names that keep wiring
independent of the local class names without introducing a second persistence
behavior to maintain.

The Node entry points use `scripts/local-database.mjs` as the single local
database adapter boundary. It owns the SQLite client connection and schema
activation; repository behavior remains in the ABAP adapters.

The browser assets cannot share an implementation the same way. SAP keeps them
in the MIME repository, where abapGit installs the `SMIM` objects from
`src/frontend`, and `ZCL_HITHUB_SAP_ASSET_STORE` reads them through
`CL_MIME_REPOSITORY_API`. The open-abap runtime has no MIME repository, so
`ZCL_HITHUB_LOCAL_ASSET_STORE` serves what `scripts/local-assets.mjs` reads
out of the same serialized files and registers during startup. Both adapters
answer the same port for `ZCL_HITHUB_STATIC_FILES`, so the request handling,
content types and revalidation stay in one place.
