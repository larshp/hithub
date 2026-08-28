CLASS ltcl_repository_purge DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS purges_deleted_repository FOR TESTING RAISING cx_static_check.
    METHODS rejects_visible_repository FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_repository_purge IMPLEMENTATION.

  METHOD purges_deleted_repository.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_objects) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    ls_repository-id = 'purge-repository-000000000000000'.
    ls_repository-name = 'purge-repository'.
    ls_repository-version = 2.
    ls_repository-deleted = abap_true.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    ls_reference-repository_id = ls_repository-id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    lo_metadata->zif_hithub_metadata_store~save_reference( ls_reference ).
    ls_object-key-repository_id = ls_repository-id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = '2222222222222222222222222222222222222222'.
    ls_object-type = 'blob'.
    ls_object-size = 1.
    ls_object-payload = CONV xstring( 'CA' ).
    lo_objects->zif_hithub_object_store~write( ls_object ).

    DATA(lo_service) = NEW zcl_hithub_repository_purge(
      io_metadata = lo_metadata io_objects = lo_objects
      io_transaction = lo_transaction ).
    DATA(ls_result) = lo_service->purge(
      iv_repository_id = ls_repository-id iv_expected_version = 2 ).
    ASSERT ls_result-success = abap_true.
    DATA(ls_read) =
      lo_metadata->zif_hithub_metadata_store~read_repository_any(
        ls_repository-id ).
    ASSERT ls_read-id IS INITIAL.
    DATA(lt_references) =
      lo_metadata->zif_hithub_metadata_store~list_references(
        ls_repository-id ).
    ASSERT lines( lt_references ) = 0.
    ASSERT lo_objects->zif_hithub_object_store~contains( ls_object-key ) =
      abap_false.
  ENDMETHOD.

  METHOD rejects_visible_repository.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_objects) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'purge-visible-000000000000000000'.
    ls_repository-name = 'purge-visible'.
    ls_repository-version = 1.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_service) = NEW zcl_hithub_repository_purge(
      io_metadata = lo_metadata io_objects = lo_objects
      io_transaction = lo_transaction ).
    DATA(ls_result) = lo_service->purge(
      iv_repository_id = ls_repository-id iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'repository must be soft deleted first'.
  ENDMETHOD.

ENDCLASS.
