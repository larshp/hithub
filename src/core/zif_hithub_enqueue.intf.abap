INTERFACE zif_hithub_enqueue
  PUBLIC.

  METHODS acquire
    IMPORTING
      iv_repository_id TYPE string
    RETURNING
      VALUE(rv_acquired) TYPE abap_bool.

  METHODS release
    IMPORTING
      iv_repository_id TYPE string.

ENDINTERFACE.
