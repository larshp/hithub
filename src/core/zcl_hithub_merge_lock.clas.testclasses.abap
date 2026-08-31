CLASS lcl_merge_lock DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_repository_lock.
    METHODS is_acquired RETURNING VALUE(rv_acquired) TYPE abap_bool.
    METHODS is_released RETURNING VALUE(rv_released) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_acquired TYPE abap_bool.
    DATA mv_released TYPE abap_bool.
ENDCLASS.

CLASS lcl_merge_lock IMPLEMENTATION.

  METHOD zif_hithub_repository_lock~acquire.
    mv_acquired = abap_true.
    rv_acquired = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~release.
    mv_released = abap_true.
    CLEAR mv_acquired.
  ENDMETHOD.

  METHOD is_acquired.
    rv_acquired = mv_acquired.
  ENDMETHOD.

  METHOD is_released.
    rv_released = mv_released.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~is_held.
    rv_held = mv_acquired.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_merge_lock DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS acquires_before_validation FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_lock IMPLEMENTATION.

  METHOD acquires_before_validation.
    DATA lo_lock TYPE REF TO lcl_merge_lock.
    DATA lo_guard TYPE REF TO zcl_hithub_merge_lock.
    lo_lock = NEW lcl_merge_lock( ).
    lo_guard = NEW zcl_hithub_merge_lock(
      io_lock = lo_lock iv_repository_id = 'merge-repository'
      iv_owner = 'merge-request-1' ).

    ASSERT lo_guard->acquire( ) = abap_true.
    ASSERT lo_lock->is_acquired( ) = abap_true.
    ASSERT lo_guard->is_held( ) = abap_true.
    lo_guard->release( ).
    ASSERT lo_lock->is_released( ) = abap_true.
    ASSERT lo_guard->is_held( ) = abap_false.
  ENDMETHOD.

ENDCLASS.
