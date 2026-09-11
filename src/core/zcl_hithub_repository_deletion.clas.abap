CLASS zcl_hithub_repository_deletion DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_result.
    TYPES   success TYPE abap_bool.
    TYPES   reason  TYPE string.
    TYPES   version TYPE int8.
    TYPES END OF ty_result.

    METHODS constructor
      IMPORTING
        io_metadata    TYPE REF TO zif_hithub_metadata_store
        io_transaction TYPE REF TO zif_hithub_transaction.
    METHODS delete
      IMPORTING
        iv_repository_id    TYPE string
        iv_expected_version TYPE int8 OPTIONAL
      RETURNING
        VALUE(rs_result)    TYPE ty_result
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.

ENDCLASS.

CLASS zcl_hithub_repository_deletion IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD delete.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA lv_version TYPE int8.

    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_transaction IS INITIAL
        OR iv_repository_id IS INITIAL.
      rs_result-reason = 'repository service is not configured'.
      RETURN.
    ENDIF.
    IF iv_expected_version IS INITIAL.
      rs_result-reason = 'repository version is required'.
      RETURN.
    ENDIF.
    ls_repository = mo_metadata->read_repository( iv_repository_id ).
    IF ls_repository-id IS INITIAL.
      rs_result-reason = 'repository was not found'.
      RETURN.
    ENDIF.
    ls_repository-deleted = abap_true.

    TRY.
        mo_transaction->start( ).
        lv_version = mo_metadata->update_repository(
          is_repository       = ls_repository
          iv_expected_version = iv_expected_version ).
        IF lv_version IS INITIAL.
          mo_transaction->rollback( ).
          rs_result-reason = 'repository version is stale'.
          RETURN.
        ENDIF.
        mo_transaction->commit( ).
      CATCH cx_root.
        mo_transaction->rollback( ).
        rs_result-reason = 'repository could not be persisted'.
        RETURN.
    ENDTRY.
    rs_result-success = abap_true.
    rs_result-version = lv_version.
  ENDMETHOD.

ENDCLASS.
