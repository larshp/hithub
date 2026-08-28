CLASS lcl_push_lock DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_repository_lock.
    METHODS acquisitions RETURNING VALUE(rv_count) TYPE i.
    METHODS releases RETURNING VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mv_acquisitions TYPE i.
    DATA mv_releases TYPE i.

ENDCLASS.

CLASS lcl_push_lock IMPLEMENTATION.

  METHOD zif_hithub_repository_lock~acquire.
    mv_acquisitions = mv_acquisitions + 1.
    rv_acquired = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~release.
    mv_releases = mv_releases + 1.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~is_held.
    rv_held = xsdbool( mv_acquisitions > mv_releases ).
  ENDMETHOD.

  METHOD acquisitions.
    rv_count = mv_acquisitions.
  ENDMETHOD.

  METHOD releases.
    rv_count = mv_releases.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS locks_all_ref_commands_once FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_lock_context FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD locks_all_ref_commands_once.
    DATA(lo_lock) = NEW lcl_push_lock( ).
    DATA(lo_guard) = NEW zcl_hithub_push_lock(
      io_lock = lo_lock iv_repository_id = 'push-lock-repository'
      iv_owner = 'request-1' ).

    DO 3 TIMES.
      ASSERT lo_guard->acquire( ) = abap_true.
    ENDDO.
    ASSERT lo_lock->acquisitions( ) = 1.
    ASSERT lo_lock->releases( ) = 0.
    lo_guard->release( ).
    ASSERT lo_lock->releases( ) = 1.
  ENDMETHOD.

  METHOD rejects_invalid_lock_context.
    DATA(lo_lock) = NEW lcl_push_lock( ).
    DATA(lo_guard) = NEW zcl_hithub_push_lock(
      io_lock = lo_lock iv_repository_id = '' iv_owner = 'request-1' ).

    ASSERT lo_guard->acquire( ) = abap_false.
    ASSERT lo_lock->acquisitions( ) = 0.
  ENDMETHOD.

ENDCLASS.
