CLASS zcl_hithub_repository_update DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_result.
    TYPES   success TYPE abap_bool.
    TYPES   reason TYPE string.
    TYPES   repository TYPE zif_hithub_metadata_store=>ty_repository.
    TYPES END OF ty_result.

    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_transaction TYPE REF TO zif_hithub_transaction.
    METHODS update
      IMPORTING
        iv_repository_id TYPE string
        iv_description TYPE string OPTIONAL
        iv_description_provided TYPE abap_bool DEFAULT abap_false
        iv_default_branch TYPE string OPTIONAL
        iv_default_branch_provided TYPE abap_bool DEFAULT abap_false
        iv_expected_version TYPE int8 OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_result
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.

ENDCLASS.

CLASS zcl_hithub_repository_update IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD update.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA lv_default_branch TYPE string.
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
    IF iv_description_provided = abap_true.
      IF strlen( iv_description ) > 255.
        rs_result-reason = 'repository description is invalid'.
        RETURN.
      ENDIF.
      ls_repository-description = iv_description.
    ENDIF.
    IF iv_default_branch_provided = abap_true.
      lv_default_branch = iv_default_branch.
      IF lv_default_branch IS INITIAL.
        rs_result-reason = 'default branch is invalid'.
        RETURN.
      ELSEIF lv_default_branch NP 'refs/*'.
        lv_default_branch = |refs/heads/{ lv_default_branch }|.
      ENDIF.
      IF zcl_hithub_ref_validator=>is_valid( lv_default_branch ) = abap_false.
        rs_result-reason = 'default branch is invalid'.
        RETURN.
      ENDIF.
      ls_repository-default_branch = lv_default_branch.
    ENDIF.

    TRY.
        mo_transaction->start( ).
        lv_version = mo_metadata->update_repository(
          is_repository = ls_repository
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
    ls_repository-version = lv_version.
    rs_result-success = abap_true.
    rs_result-repository = ls_repository.
  ENDMETHOD.

ENDCLASS.
