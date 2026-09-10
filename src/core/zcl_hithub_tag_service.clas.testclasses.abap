CLASS ltcl_tag_service DEFINITION
  FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS manages_tag_lifecycle FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_tag_service IMPLEMENTATION.
  METHOD manages_tag_lifecycle.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_tag_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = |tag-service-000000000000000000|.
    DATA(ls_created) = lo_service->create(
      iv_repository_id = lv_repository_id iv_name = 'release/v1'
      iv_oid = '1111111111111111111111111111111111111111' ).
    cl_abap_unit_assert=>assert_true( act = ls_created-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_created-reference-name
      exp = 'refs/tags/release/v1' ).
    DATA(ls_updated) = lo_service->update(
      iv_repository_id = lv_repository_id iv_name = 'release/v1'
      iv_oid = '2222222222222222222222222222222222222222'
      iv_expected_version = 1 ).
    cl_abap_unit_assert=>assert_true( act = ls_updated-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_updated-reference-version
      exp = 2 ).
    DATA(ls_deleted) = lo_service->delete(
      iv_repository_id = lv_repository_id iv_name = 'release/v1'
      iv_expected_version = 2 ).
    cl_abap_unit_assert=>assert_true( act = ls_deleted-success ).
    DATA(ls_after) = lo_service->find(
      iv_repository_id = lv_repository_id iv_name = 'release/v1' ).
    cl_abap_unit_assert=>assert_initial( act = ls_after-name ).
  ENDMETHOD.
ENDCLASS.
