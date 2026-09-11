INTERFACE zif_hithub_hashing
  PUBLIC.

  METHODS digest
    IMPORTING
      iv_algorithm  TYPE string
      iv_payload    TYPE xstring
    RETURNING
      VALUE(rv_oid) TYPE string
    RAISING
      cx_static_check.

  METHODS is_valid
    IMPORTING
      iv_algorithm    TYPE string
      iv_oid          TYPE string
    RETURNING
      VALUE(rv_valid) TYPE abap_bool.

ENDINTERFACE.
