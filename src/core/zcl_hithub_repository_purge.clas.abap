CLASS zcl_hithub_repository_purge DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_result.
    TYPES   success TYPE abap_bool.
    TYPES   reason TYPE string.
    TYPES END OF ty_result.

    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_objects TYPE REF TO zif_hithub_object_store
        io_transaction TYPE REF TO zif_hithub_transaction.
    METHODS purge
      IMPORTING
        iv_repository_id TYPE string
        iv_expected_version TYPE int8
      RETURNING
        VALUE(rs_result) TYPE ty_result
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_objects TYPE REF TO zif_hithub_object_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.

ENDCLASS.

CLASS zcl_hithub_repository_purge IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD purge.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA lv_purged TYPE abap_bool.

    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_objects IS INITIAL
        OR mo_transaction IS INITIAL OR iv_repository_id IS INITIAL.
      rs_result-reason = 'repository service is not configured'.
      RETURN.
    ENDIF.
    IF iv_expected_version IS INITIAL.
      rs_result-reason = 'repository version is required'.
      RETURN.
    ENDIF.
    ls_repository = mo_metadata->read_repository_any(
      iv_repository_id ).
    IF ls_repository-id IS INITIAL.
      rs_result-reason = 'repository was not found'.
      RETURN.
    ENDIF.
    IF ls_repository-deleted <> abap_true.
      rs_result-reason = 'repository must be soft deleted first'.
      RETURN.
    ENDIF.

    TRY.
        mo_transaction->start( ).
        lv_purged = mo_metadata->purge_repository(
          iv_repository_id = iv_repository_id
          iv_expected_version = iv_expected_version ).
        IF lv_purged = abap_false.
          mo_transaction->rollback( ).
          rs_result-reason = 'repository version is stale'.
          RETURN.
        ENDIF.
        IF mo_objects->purge_repository( iv_repository_id ) = abap_false.
          mo_transaction->rollback( ).
          rs_result-reason = 'repository objects could not be purged'.
          RETURN.
        ENDIF.
        mo_transaction->commit( ).
      CATCH cx_root.
        mo_transaction->rollback( ).
        rs_result-reason = 'repository could not be purged'.
        RETURN.
    ENDTRY.
    rs_result-success = abap_true.
  ENDMETHOD.

ENDCLASS.
