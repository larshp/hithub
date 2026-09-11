CLASS ltcl_branch_service DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_lifecycle_repository TYPE string
      VALUE 'branch-service-00000000000000000'.
    CONSTANTS c_stale_repository TYPE string
      VALUE 'branch-stale-00000000000000000000'.

    METHODS setup RAISING cx_static_check.
    METHODS teardown RAISING cx_static_check.
    METHODS manages_branch_lifecycle FOR TESTING RAISING cx_static_check.
    METHODS rejects_stale_update FOR TESTING RAISING cx_static_check.

    "! create( ), update( ) and delete( ) commit, so a branch outlives the
    "! rollback ABAP Unit does after each test method and the fixed fixture
    "! ids would collide on the next run.
    METHODS drop_fixture_branches RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_branch_service IMPLEMENTATION.

  METHOD setup.
    " Recover from a run that ended before its teardown.
    drop_fixture_branches( ).
  ENDMETHOD.

  METHOD teardown.
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).

    lo_transaction->zif_hithub_transaction~start( ).
    drop_fixture_branches( ).
    " The deletes have to be committed, otherwise the rollback that ends
    " the test method puts the branches straight back.
    lo_transaction->zif_hithub_transaction~commit( ).
  ENDMETHOD.

  METHOD drop_fixture_branches.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA lt_repositories TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_repository_id TYPE string.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    APPEND c_lifecycle_repository TO lt_repositories.
    APPEND c_stale_repository TO lt_repositories.
    LOOP AT lt_repositories INTO lv_repository_id.
      LOOP AT lo_metadata->zif_hithub_metadata_store~list_references(
          lv_repository_id ) INTO ls_reference.
        lo_metadata->zif_hithub_metadata_store~delete_reference(
          iv_repository_id = lv_repository_id
          iv_name          = ls_reference-name ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD manages_branch_lifecycle.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_service) = NEW zcl_hithub_branch_service(
      io_metadata = lo_metadata io_transaction = lo_transaction ).
    DATA(lv_repository_id) = c_lifecycle_repository.
    DATA(lv_oid) = |1111111111111111111111111111111111111111|.
    " setup( ) and teardown( ) clear the fixture, so anything still here
    " came from outside this test.
    cl_abap_unit_assert=>assert_initial(
      act = lo_service->find(
        iv_repository_id = lv_repository_id iv_name = 'feature/test' )-name
      msg = 'the branch was left behind by an earlier committed run' ).
    DATA(ls_result) = lo_service->create(
      iv_repository_id = lv_repository_id
      iv_name          = 'feature/test'
      iv_oid           = lv_oid ).
    cl_abap_unit_assert=>assert_initial(
      act = ls_result-reason
      msg = 'the branch could not be created' ).
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
    DATA(lv_repository_id) = c_stale_repository.
    " create( ) commits, so a leftover branch would fail this as a
    " duplicate. setup( ) and teardown( ) clear the fixture.
    cl_abap_unit_assert=>assert_initial(
      act = lo_service->find(
        iv_repository_id = lv_repository_id iv_name = 'main' )-name
      msg = 'refs/heads/main was left behind by an earlier committed run' ).
    DATA(ls_created) = lo_service->create(
      iv_repository_id = lv_repository_id
      iv_name          = 'main'
      iv_oid           = '3333333333333333333333333333333333333333' ).
    cl_abap_unit_assert=>assert_initial(
      act = ls_created-reason
      msg = 'the branch could not be created' ).
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
