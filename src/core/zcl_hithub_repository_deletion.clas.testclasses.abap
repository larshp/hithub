CLASS ltcl_repository_deletion DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS soft_deletes_with_version FOR TESTING RAISING cx_static_check.
    METHODS rejects_stale_delete FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_repository_deletion IMPLEMENTATION.

  METHOD soft_deletes_with_version.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'delete-repository-0000000000000000'.
    ls_repository-name = 'delete-repository'.
    ls_repository-version = 1.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_service) = NEW zcl_hithub_repository_deletion(
      io_metadata = lo_metadata io_transaction = lo_transaction ).

    DATA(ls_result) = lo_service->delete(
      iv_repository_id = ls_repository-id iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_true.
    ASSERT ls_result-version = 2.
    DATA(ls_read) = lo_metadata->zif_hithub_metadata_store~read_repository(
      ls_repository-id ).
    ASSERT ls_read-id IS INITIAL.
    DATA(lt_repositories) =
      lo_metadata->zif_hithub_metadata_store~list_repositories( ).
    READ TABLE lt_repositories WITH KEY id = ls_repository-id
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc <> 0.
  ENDMETHOD.

  METHOD rejects_stale_delete.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'delete-stale-000000000000000000000'.
    ls_repository-name = 'delete-stale'.
    ls_repository-version = 2.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_service) = NEW zcl_hithub_repository_deletion(
      io_metadata = lo_metadata io_transaction = lo_transaction ).

    DATA(ls_result) = lo_service->delete(
      iv_repository_id = ls_repository-id iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'repository version is stale'.
  ENDMETHOD.

ENDCLASS.
