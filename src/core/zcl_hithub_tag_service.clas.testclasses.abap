CLASS ltcl_tag_service DEFINITION
  FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS manages_tag_lifecycle FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_tag_service IMPLEMENTATION.
  METHOD manages_tag_lifecycle.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_tag_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = 'tag-service-000000000000000000'.
    DATA(ls_created) = lo_service->create(
      iv_repository_id = lv_repository_id iv_name = 'release/v1'
      iv_oid = '1111111111111111111111111111111111111111' ).
    ASSERT ls_created-success = abap_true.
    ASSERT ls_created-reference-name = 'refs/tags/release/v1'.
    DATA(ls_updated) = lo_service->update(
      iv_repository_id = lv_repository_id iv_name = 'release/v1'
      iv_oid = '2222222222222222222222222222222222222222'
      iv_expected_version = 1 ).
    ASSERT ls_updated-success = abap_true.
    ASSERT ls_updated-reference-version = 2.
    DATA(ls_deleted) = lo_service->delete(
      iv_repository_id = lv_repository_id iv_name = 'release/v1'
      iv_expected_version = 2 ).
    ASSERT ls_deleted-success = abap_true.
    DATA(ls_after) = lo_service->find(
      iv_repository_id = lv_repository_id iv_name = 'release/v1' ).
    ASSERT ls_after-name IS INITIAL.
  ENDMETHOD.
ENDCLASS.
