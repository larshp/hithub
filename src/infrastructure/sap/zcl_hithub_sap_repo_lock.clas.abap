CLASS zcl_hithub_sap_repo_lock DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_repository_lock.

    METHODS constructor
      IMPORTING
        io_enqueue TYPE REF TO zif_hithub_enqueue OPTIONAL.

  PRIVATE SECTION.
    DATA mv_repository_id TYPE string.
    DATA mv_held TYPE abap_bool.
    DATA mo_enqueue TYPE REF TO zif_hithub_enqueue.

    METHODS try_enqueue
      RETURNING
        VALUE(rv_acquired) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_sap_repo_lock IMPLEMENTATION.

  METHOD try_enqueue.
    CLEAR rv_acquired.
    IF mv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    IF mo_enqueue IS NOT INITIAL.
      rv_acquired = mo_enqueue->acquire( mv_repository_id ).
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    IF io_enqueue IS INITIAL.
      mo_enqueue = NEW zcl_hithub_sap_enqueue( ).
    ELSE.
      mo_enqueue = io_enqueue.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~acquire.
    CLEAR rv_acquired.
    IF mv_held = abap_true.
      rv_acquired = abap_true.
      RETURN.
    ENDIF.
    IF iv_repository_id IS INITIAL OR iv_owner IS INITIAL
        OR iv_timeout_seconds < 0.
      RETURN.
    ENDIF.
    mv_repository_id = iv_repository_id.
    rv_acquired = try_enqueue( ).
    IF rv_acquired = abap_true OR iv_timeout_seconds = 0.
      mv_held = rv_acquired.
      RETURN.
    ENDIF.
    DO iv_timeout_seconds TIMES.
      WAIT UP TO 1 SECONDS.
      rv_acquired = try_enqueue( ).
      IF rv_acquired = abap_true.
        mv_held = abap_true.
        RETURN.
      ENDIF.
    ENDDO.
    CLEAR mv_repository_id.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~release.
    IF mv_held <> abap_true OR iv_repository_id <> mv_repository_id
        OR iv_owner IS INITIAL.
      RETURN.
    ENDIF.
    IF mo_enqueue IS NOT INITIAL.
      mo_enqueue->release( mv_repository_id ).
    ENDIF.
    CLEAR mv_held.
    CLEAR mv_repository_id.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~is_held.
    rv_held = mv_held.
  ENDMETHOD.

ENDCLASS.
