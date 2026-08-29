CLASS zcl_hithub_merge_lock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

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
    DATA mo_guard TYPE REF TO zcl_hithub_push_lock.
ENDCLASS.

CLASS zcl_hithub_merge_lock IMPLEMENTATION.

  METHOD constructor.
    mo_guard = NEW zcl_hithub_push_lock(
      io_lock = io_lock iv_repository_id = iv_repository_id
      iv_owner = iv_owner iv_timeout_seconds = iv_timeout_seconds ).
  ENDMETHOD.

  METHOD acquire.
    CLEAR rv_acquired.
    IF mo_guard IS INITIAL.
      RETURN.
    ENDIF.
    rv_acquired = mo_guard->acquire( ).
  ENDMETHOD.

  METHOD release.
    IF mo_guard IS INITIAL.
      RETURN.
    ENDIF.
    mo_guard->release( ).
  ENDMETHOD.

  METHOD is_held.
    CLEAR rv_held.
    IF mo_guard IS INITIAL.
      RETURN.
    ENDIF.
    rv_held = mo_guard->is_held( ).
  ENDMETHOD.

ENDCLASS.
