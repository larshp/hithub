CLASS lcl_merge_target_lock DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_repository_lock.
    METHODS is_acquired RETURNING VALUE(rv_acquired) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_acquired TYPE abap_bool.
ENDCLASS.

CLASS lcl_merge_target_lock IMPLEMENTATION.

  METHOD zif_hithub_repository_lock~acquire.
    mv_acquired = abap_true.
    rv_acquired = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~release.
    CLEAR mv_acquired.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~is_held.
    rv_held = mv_acquired.
  ENDMETHOD.

  METHOD is_acquired.
    rv_acquired = mv_acquired.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_merge_target DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS rechecks_target_under_lock FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_target IMPLEMENTATION.

  METHOD rechecks_target_under_lock.
    DATA lo_lock TYPE REF TO lcl_merge_target_lock.
    DATA lo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA lo_target TYPE REF TO zcl_hithub_merge_target.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_oid TYPE string.
    lo_lock = NEW lcl_merge_target_lock( ).
    lo_metadata = NEW zcl_hithub_local_meta_store( ).
    lv_oid = '1111111111111111111111111111111111111111'.
    ls_reference-repository_id = 'merge-target-repository'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_oid.
    ASSERT lo_metadata->create_reference( ls_reference ) = 1.
    lo_target = NEW zcl_hithub_merge_target(
      io_lock = lo_lock io_metadata = lo_metadata
      iv_repository_id = ls_reference-repository_id iv_owner = 'merge-1' ).

    ASSERT lo_target->check(
      iv_ref_name = ls_reference-name iv_algorithm = 'sha1'
      iv_expected_oid = lv_oid ) = abap_true.
    ASSERT lo_lock->is_acquired( ) = abap_false.
    ASSERT lo_target->check(
      iv_ref_name = ls_reference-name iv_algorithm = 'sha1'
      iv_expected_oid = '2222222222222222222222222222222222222222' ) =
        abap_false.
  ENDMETHOD.

ENDCLASS.
