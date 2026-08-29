CLASS zcl_hithub_push_lock DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_lock            TYPE REF TO zif_hithub_repository_lock
        iv_repository_id   TYPE string
        iv_owner           TYPE string
        iv_timeout_seconds TYPE i DEFAULT 10.

    METHODS acquire
      RETURNING
        VALUE(rv_acquired) TYPE abap_bool
      RAISING
        cx_static_check.

    METHODS release
      RAISING
        cx_static_check.

    METHODS is_held
      RETURNING
        VALUE(rv_held) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mo_lock TYPE REF TO zif_hithub_repository_lock.
    DATA mv_repository_id TYPE string.
    DATA mv_owner TYPE string.
    DATA mv_timeout_seconds TYPE i.
    DATA mv_acquired TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_push_lock IMPLEMENTATION.

  METHOD constructor.
    mo_lock = io_lock.
    mv_repository_id = iv_repository_id.
    mv_owner = iv_owner.
    mv_timeout_seconds = iv_timeout_seconds.
  ENDMETHOD.

  METHOD acquire.
    rv_acquired = mv_acquired.
    IF mv_acquired = abap_true.
      RETURN.
    ENDIF.
    IF mo_lock IS INITIAL OR mv_repository_id IS INITIAL OR mv_owner IS INITIAL
        OR mv_timeout_seconds < 0.
      RETURN.
    ENDIF.
    mv_acquired = mo_lock->acquire(
      iv_repository_id = mv_repository_id iv_owner = mv_owner
      iv_timeout_seconds = mv_timeout_seconds ).
    rv_acquired = mv_acquired.
  ENDMETHOD.

  METHOD release.
    IF mv_acquired <> abap_true OR mo_lock IS INITIAL.
      RETURN.
    ENDIF.
    mo_lock->release(
      iv_repository_id = mv_repository_id iv_owner = mv_owner ).
    CLEAR mv_acquired.
  ENDMETHOD.

  METHOD is_held.
    rv_held = mv_acquired.
  ENDMETHOD.

ENDCLASS.
