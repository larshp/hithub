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
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
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
    cl_abap_unit_assert=>assert_true( act = ls_result-success ).
    DATA(ls_read) =
      lo_metadata->zif_hithub_metadata_store~read_repository_any(
        ls_repository-id ).
    cl_abap_unit_assert=>assert_initial( act = ls_read-id ).
    DATA(lt_references) =
      lo_metadata->zif_hithub_metadata_store~list_references(
        ls_repository-id ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_references ) exp = 0 ).
    cl_abap_unit_assert=>assert_false(
      act = lo_objects->zif_hithub_object_store~contains( ls_object-key ) ).
  ENDMETHOD.

  METHOD rejects_visible_repository.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_objects) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
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
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'repository must be soft deleted first' ).
  ENDMETHOD.

ENDCLASS.
