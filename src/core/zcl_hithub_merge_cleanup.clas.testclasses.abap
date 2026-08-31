CLASS ltcl_merge_cleanup DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS supports_optional_delete FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_cleanup IMPLEMENTATION.

  METHOD supports_optional_delete.
    DATA lo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA lo_transaction TYPE REF TO zif_hithub_transaction.
    DATA lo_cleanup TYPE REF TO zcl_hithub_merge_cleanup.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    lo_metadata = NEW zcl_hithub_local_meta_store( ).
    lo_transaction = NEW zcl_hithub_local_unit_work( ).
    ls_reference-repository_id = 'merge-cleanup-repository'.
    ls_reference-name = 'refs/heads/feature'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    ASSERT lo_metadata->create_reference( ls_reference ) = 1.
    lo_cleanup = NEW zcl_hithub_merge_cleanup(
      io_metadata = lo_metadata io_transaction = lo_transaction ).

    ASSERT lo_cleanup->cleanup_source(
      iv_enabled = abap_false iv_repository_id = ls_reference-repository_id
      iv_source_ref = ls_reference-name ) = abap_true.
    ASSERT lo_metadata->read_reference(
      iv_repository_id = ls_reference-repository_id
      iv_name          = ls_reference-name )-name IS NOT INITIAL.
    ASSERT lo_cleanup->cleanup_source(
      iv_enabled = abap_true iv_repository_id = ls_reference-repository_id
      iv_source_ref = ls_reference-name iv_expected_version = 1 ) = abap_true.
    ASSERT lo_metadata->read_reference(
      iv_repository_id = ls_reference-repository_id
      iv_name          = ls_reference-name )-name IS INITIAL.
  ENDMETHOD.

ENDCLASS.
