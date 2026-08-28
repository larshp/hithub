CLASS zcl_hithub_merge_cleanup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_transaction TYPE REF TO zif_hithub_transaction.

    METHODS cleanup_source
      IMPORTING
        iv_enabled TYPE abap_bool
        iv_repository_id TYPE string
        iv_source_ref TYPE string
        iv_expected_version TYPE int8 OPTIONAL
      RETURNING
        VALUE(rv_success) TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
ENDCLASS.

CLASS zcl_hithub_merge_cleanup IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD cleanup_source.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    CLEAR rv_success.
    IF iv_enabled = abap_false.
      rv_success = abap_true.
      RETURN.
    ENDIF.
    IF mo_metadata IS INITIAL OR mo_transaction IS INITIAL
        OR iv_repository_id IS INITIAL
        OR zcl_hithub_ref_validator=>is_valid( iv_source_ref ) = abap_false.
      RETURN.
    ENDIF.
    ls_reference = mo_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = iv_source_ref ).
    IF ls_reference-name IS INITIAL.
      rv_success = abap_true.
      RETURN.
    ENDIF.
    mo_transaction->start( ).
    mo_metadata->delete_reference(
      iv_repository_id = iv_repository_id iv_name = iv_source_ref
      iv_expected_version = iv_expected_version ).
    IF mo_metadata->read_reference(
        iv_repository_id = iv_repository_id iv_name = iv_source_ref )-name IS NOT INITIAL.
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.
    mo_transaction->commit( ).
    rv_success = abap_true.
  ENDMETHOD.

ENDCLASS.
