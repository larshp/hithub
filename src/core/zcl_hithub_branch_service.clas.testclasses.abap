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
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_branch_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = 'branch-service-00000000000000000'.
    DATA(lv_oid) = '1111111111111111111111111111111111111111'.
    DATA(ls_result) = lo_service->create(
      iv_repository_id = lv_repository_id
      iv_name = 'feature/test'
      iv_oid = lv_oid ).
    ASSERT ls_result-success = abap_true.
    ASSERT ls_result-reference-name = 'refs/heads/feature/test'.
    ASSERT ls_result-reference-version = 1.

    DATA(lt_references) = lo_service->list( lv_repository_id ).
    ASSERT lines( lt_references ) = 1.
    DATA(ls_found) = lo_service->find(
      iv_repository_id = lv_repository_id iv_name = 'feature/test' ).
    ASSERT ls_found-oid = lv_oid.

    DATA(ls_update) = lo_service->update(
      iv_repository_id = lv_repository_id
      iv_name = 'feature/test'
      iv_oid = '2222222222222222222222222222222222222222'
      iv_expected_version = 1 ).
    ASSERT ls_update-success = abap_true.
    ASSERT ls_update-reference-version = 2.

    DATA(ls_delete) = lo_service->delete(
      iv_repository_id = lv_repository_id
      iv_name = 'refs/heads/feature/test'
      iv_expected_version = 2 ).
    ASSERT ls_delete-success = abap_true.
    DATA(ls_after_delete) = lo_service->find(
      iv_repository_id = lv_repository_id iv_name = 'feature/test' ).
    ASSERT ls_after_delete-name IS INITIAL.
  ENDMETHOD.

  METHOD rejects_stale_update.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_branch_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = 'branch-stale-00000000000000000000'.
    DATA(ls_created) = lo_service->create(
      iv_repository_id = lv_repository_id
      iv_name = 'main'
      iv_oid = '3333333333333333333333333333333333333333' ).
    ASSERT ls_created-success = abap_true.
    DATA(ls_result) = lo_service->update(
      iv_repository_id = lv_repository_id
      iv_name = 'main'
      iv_oid = '4444444444444444444444444444444444444444'
      iv_expected_version = 0 ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'branch input is invalid'.
  ENDMETHOD.

ENDCLASS.
