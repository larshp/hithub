INTERFACE zif_hithub_identity
  PUBLIC.

  METHODS uuid
    RETURNING
      VALUE(rv_uuid) TYPE string
    RAISING
      cx_static_check.

  METHODS random_bytes
    IMPORTING
      iv_length       TYPE i
    RETURNING
      VALUE(rv_bytes) TYPE xstring
    RAISING
      cx_static_check.

ENDINTERFACE.
