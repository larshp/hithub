INTERFACE zif_hithub_transaction
  PUBLIC.

  METHODS start
    RAISING
      cx_static_check.

  METHODS commit
    RAISING
      cx_static_check.

  METHODS rollback
    RAISING
      cx_static_check.

  METHODS is_active
    RETURNING
      VALUE(rv_active) TYPE abap_bool.

ENDINTERFACE.
