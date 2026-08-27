INTERFACE zif_hithub_clock
  PUBLIC.

  METHODS now
    RETURNING
      VALUE(rv_timestamp) TYPE timestampl.

ENDINTERFACE.
