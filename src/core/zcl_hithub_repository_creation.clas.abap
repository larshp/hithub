CLASS zcl_hithub_repository_creation DEFINITION
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
        io_transaction TYPE REF TO zif_hithub_transaction
        io_identity TYPE REF TO zif_hithub_identity.

    METHODS create
      IMPORTING
        iv_name TYPE string
        iv_description TYPE string OPTIONAL
        iv_default_branch TYPE string OPTIONAL
        iv_actor TYPE string OPTIONAL
        iv_idempotency_key TYPE string OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_result
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    DATA mo_identity TYPE REF TO zif_hithub_identity.

ENDCLASS.

CLASS zcl_hithub_repository_creation IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
    mo_identity = io_identity.
  ENDMETHOD.

  METHOD create.
    DATA lt_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
    DATA ls_existing TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA lv_name TYPE string.
    DATA lv_existing_name TYPE string.
    DATA lv_default_branch TYPE string.
    DATA lv_idempotent_id TYPE string.

    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_transaction IS INITIAL
        OR mo_identity IS INITIAL.
      rs_result-reason = 'repository service is not configured'.
      RETURN.
    ENDIF.
    IF iv_name IS INITIAL OR strlen( iv_name ) > 100.
      rs_result-reason = 'repository name is invalid'.
      RETURN.
    ENDIF.
    FIND REGEX '^[A-Za-z0-9][A-Za-z0-9._-]*$' IN iv_name.
    IF sy-subrc <> 0.
      rs_result-reason = 'repository name is invalid'.
      RETURN.
    ENDIF.
    lv_name = iv_name.
    TRANSLATE lv_name TO LOWER CASE.

    IF iv_actor IS NOT INITIAL AND iv_idempotency_key IS NOT INITIAL.
      lv_idempotent_id = mo_metadata->read_idempotency(
        iv_actor = iv_actor iv_key = iv_idempotency_key ).
      IF lv_idempotent_id IS NOT INITIAL.
        rs_result-repository = mo_metadata->read_repository( lv_idempotent_id ).
        IF rs_result-repository-id IS NOT INITIAL.
          rs_result-success = abap_true.
          RETURN.
        ENDIF.
        rs_result-reason = 'idempotency key is no longer valid'.
        RETURN.
      ENDIF.
    ENDIF.

    lt_repositories = mo_metadata->list_repositories( ).
    LOOP AT lt_repositories INTO ls_existing.
      lv_existing_name = ls_existing-name.
      TRANSLATE lv_existing_name TO LOWER CASE.
      IF lv_existing_name = lv_name.
        rs_result-reason = 'repository already exists'.
        RETURN.
      ENDIF.
    ENDLOOP.

    lv_default_branch = iv_default_branch.
    IF lv_default_branch IS INITIAL.
      lv_default_branch = 'refs/heads/main'.
    ELSEIF lv_default_branch NP 'refs/*'.
      lv_default_branch = |refs/heads/{ lv_default_branch }|.
    ENDIF.
    IF zcl_hithub_ref_validator=>is_valid( lv_default_branch ) = abap_false.
      rs_result-reason = 'default branch is invalid'.
      RETURN.
    ENDIF.

    ls_repository-id = mo_identity->uuid( ).
    IF ls_repository-id IS INITIAL OR strlen( ls_repository-id ) > 36.
      rs_result-reason = 'repository identity could not be generated'.
      RETURN.
    ENDIF.
    ls_repository-name = lv_name.
    ls_repository-description = iv_description.
    ls_repository-default_branch = lv_default_branch.
    ls_repository-version = 1.
    CLEAR ls_repository-deleted.

    TRY.
        mo_transaction->start( ).
        mo_metadata->save_repository( ls_repository ).
        IF iv_actor IS NOT INITIAL AND iv_idempotency_key IS NOT INITIAL
            AND mo_metadata->save_idempotency(
              iv_actor = iv_actor iv_key = iv_idempotency_key
              iv_subject_id = ls_repository-id ) = abap_false.
          mo_transaction->rollback( ).
          rs_result-reason = 'idempotency key is already in use'.
          RETURN.
        ENDIF.
        mo_transaction->commit( ).
      CATCH cx_root.
        mo_transaction->rollback( ).
        rs_result-reason = 'repository could not be persisted'.
        RETURN.
    ENDTRY.
    rs_result-success = abap_true.
    rs_result-repository = ls_repository.
  ENDMETHOD.

ENDCLASS.
