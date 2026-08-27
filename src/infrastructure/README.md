# Persistence adapters

The local and SAP repository adapters intentionally share the same Open SQL
implementation. The local runtime supplies an SQLite connection to the ABAP
runtime, while SAP supplies its normal Open SQL connection and activated DDIC
tables. The explicit SAP classes are deployment-facing names that keep wiring
independent of the local class names without introducing a second persistence
behavior to maintain.
