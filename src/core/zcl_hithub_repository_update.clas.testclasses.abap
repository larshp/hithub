CLASS ltcl_repository_update DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS updates_with_compare_and_swap FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_branch_no_version FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_repository_update IMPLEMENTATION.

  METHOD updates_with_compare_and_swap.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'update-repository-0000000000000000'.
    ls_repository-name = 'update-repository'.
    ls_repository-description = 'old'.
    ls_repository-default_branch = 'refs/heads/main'.
    ls_repository-version = 1.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_service) = NEW zcl_hithub_repository_update(
      io_metadata = lo_metadata io_transaction = lo_transaction ).

    DATA(ls_result) = lo_service->update(
      iv_repository_id = ls_repository-id
      iv_description = 'new'
      iv_description_provided = abap_true
      iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_true.
    ASSERT ls_result-repository-description = 'new'.
    ASSERT ls_result-repository-version = 2.

    ls_result = lo_service->update(
      iv_repository_id = ls_repository-id
      iv_description = 'stale'
      iv_description_provided = abap_true
      iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'repository version is stale'.
  ENDMETHOD.

  METHOD rejects_bad_branch_no_version.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'update-invalid-000000000000000000'.
    ls_repository-name = 'update-invalid'.
    ls_repository-default_branch = 'refs/heads/main'.
    ls_repository-version = 1.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_service) = NEW zcl_hithub_repository_update(
      io_metadata = lo_metadata io_transaction = lo_transaction ).

    DATA(ls_result) = lo_service->update(
      iv_repository_id = ls_repository-id
      iv_default_branch = 'bad branch'
      iv_default_branch_provided = abap_true
      iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'default branch is invalid'.

    ls_result = lo_service->update(
      iv_repository_id = ls_repository-id ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'repository version is required'.
  ENDMETHOD.

ENDCLASS.
