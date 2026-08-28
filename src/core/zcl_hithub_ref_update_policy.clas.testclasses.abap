CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS accepts_new_ref FOR TESTING RAISING cx_static_check.
    METHODS accepts_current_oid FOR TESTING RAISING cx_static_check.
    METHODS rejects_stale_oid FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD accepts_new_ref.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).

    ASSERT zcl_hithub_ref_update_policy=>old_oid_matches(
      io_metadata = lo_metadata iv_repository_id = 'update-policy-create-000000'
      iv_ref_name = 'refs/heads/main' iv_algorithm = 'sha1'
      iv_old_oid = '0000000000000000000000000000000000000000' ) = abap_true.
  ENDMETHOD.

  METHOD accepts_current_oid.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_repository_id TYPE string.

    lv_repository_id = 'update-policy-current-000000'.
    ls_reference-repository_id = lv_repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    ASSERT lo_metadata->zif_hithub_metadata_store~save_reference(
      ls_reference ) = 1.
    ASSERT zcl_hithub_ref_update_policy=>old_oid_matches(
      io_metadata = lo_metadata iv_repository_id = lv_repository_id
      iv_ref_name = ls_reference-name iv_algorithm = 'sha1'
      iv_old_oid = ls_reference-oid ) = abap_true.
  ENDMETHOD.

  METHOD rejects_stale_oid.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_repository_id TYPE string.

    lv_repository_id = 'update-policy-stale-000000'.
    ls_reference-repository_id = lv_repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = '2222222222222222222222222222222222222222'.
    ASSERT lo_metadata->zif_hithub_metadata_store~save_reference(
      ls_reference ) = 1.
    ASSERT zcl_hithub_ref_update_policy=>old_oid_matches(
      io_metadata = lo_metadata iv_repository_id = lv_repository_id
      iv_ref_name = ls_reference-name iv_algorithm = 'sha1'
      iv_old_oid = '3333333333333333333333333333333333333333' ) = abap_false.
  ENDMETHOD.

ENDCLASS.
