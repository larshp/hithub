CLASS ltcl_branch_service DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS manages_branch_lifecycle FOR TESTING RAISING cx_static_check.
    METHODS rejects_stale_update FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_branch_service IMPLEMENTATION.

  METHOD manages_branch_lifecycle.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_branch_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = |branch-service-00000000000000000|.
    DATA(lv_oid) = |1111111111111111111111111111111111111111|.
    DATA(ls_result) = lo_service->create(
      iv_repository_id = lv_repository_id
      iv_name          = 'feature/test'
      iv_oid           = lv_oid ).
    cl_abap_unit_assert=>assert_true( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reference-name
      exp = 'refs/heads/feature/test' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reference-version
      exp = 1 ).

    DATA(lt_references) = lo_service->list( lv_repository_id ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_references ) exp = 1 ).
    DATA(ls_found) = lo_service->find(
      iv_repository_id = lv_repository_id iv_name = 'feature/test' ).
    cl_abap_unit_assert=>assert_equals( act = ls_found-oid exp = lv_oid ).

    DATA(ls_update) = lo_service->update(
      iv_repository_id    = lv_repository_id
      iv_name             = 'feature/test'
      iv_oid              = '2222222222222222222222222222222222222222'
      iv_expected_version = 1 ).
    cl_abap_unit_assert=>assert_true( act = ls_update-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_update-reference-version
      exp = 2 ).

    DATA(ls_delete) = lo_service->delete(
      iv_repository_id    = lv_repository_id
      iv_name             = 'refs/heads/feature/test'
      iv_expected_version = 2 ).
    cl_abap_unit_assert=>assert_true( act = ls_delete-success ).
    DATA(ls_after_delete) = lo_service->find(
      iv_repository_id = lv_repository_id iv_name = 'feature/test' ).
    cl_abap_unit_assert=>assert_initial( act = ls_after_delete-name ).
  ENDMETHOD.

  METHOD rejects_stale_update.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_branch_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = |branch-stale-00000000000000000000|.
    DATA(ls_created) = lo_service->create(
      iv_repository_id = lv_repository_id
      iv_name          = 'main'
      iv_oid           = '3333333333333333333333333333333333333333' ).
    cl_abap_unit_assert=>assert_true( act = ls_created-success ).
    DATA(ls_result) = lo_service->update(
      iv_repository_id    = lv_repository_id
      iv_name             = 'main'
      iv_oid              = '4444444444444444444444444444444444444444'
      iv_expected_version = 0 ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'branch input is invalid' ).
  ENDMETHOD.

ENDCLASS.
