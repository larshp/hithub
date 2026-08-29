INTERFACE zif_hithub_repository_lock
  PUBLIC.

  METHODS acquire
    IMPORTING
      iv_repository_id   TYPE string
      iv_owner           TYPE string
      iv_timeout_seconds TYPE i DEFAULT 10
    RETURNING
      VALUE(rv_acquired) TYPE abap_bool
    RAISING
      cx_static_check.

  METHODS release
    IMPORTING
      iv_repository_id TYPE string
      iv_owner         TYPE string
    RAISING
      cx_static_check.

  METHODS is_held
    IMPORTING
      iv_repository_id TYPE string
      iv_owner         TYPE string
    RETURNING
      VALUE(rv_held)   TYPE abap_bool.

ENDINTERFACE.
