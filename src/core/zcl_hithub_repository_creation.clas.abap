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
        io_objects TYPE REF TO zif_hithub_object_store
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
    DATA mo_objects TYPE REF TO zif_hithub_object_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    DATA mo_identity TYPE REF TO zif_hithub_identity.

ENDCLASS.

CLASS zcl_hithub_repository_creation IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
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
    DATA lv_readme_payload TYPE xstring.
    DATA lv_tree_payload TYPE xstring.
    DATA lv_commit_payload TYPE xstring.
    DATA lv_blob_oid TYPE string.
    DATA lv_tree_oid TYPE string.
    DATA lv_commit_oid TYPE string.
    DATA lv_ref_version TYPE int8.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_tree_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_tree_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA lo_writer TYPE REF TO zcl_hithub_object_writer.
    DATA lo_output TYPE REF TO cl_abap_conv_out_ce.

    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_objects IS INITIAL
        OR mo_transaction IS INITIAL
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

    lo_output = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
    lo_output->write( data = |# { lv_name }| &&
      cl_abap_char_utilities=>newline ).
    lv_readme_payload = lo_output->get_buffer( ).
    lv_blob_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_readme_payload ).

    CLEAR ls_tree_entry.
    ls_tree_entry-mode = '100644'.
    ls_tree_entry-name = 'README.md'.
    ls_tree_entry-oid = CONV xstring( lv_blob_oid ).
    APPEND ls_tree_entry TO lt_tree_entries.
    lv_tree_payload = zcl_hithub_tree_codec=>encode( lt_tree_entries ).
    lv_tree_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'tree' iv_payload = lv_tree_payload ).

    ls_commit-tree = lv_tree_oid.
    ls_commit-author = 'HitHub <hithub@localhost> 0 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = 'Initial commit'.
    lv_commit_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    lv_commit_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_commit_payload ).

    TRY.
        mo_transaction->start( ).
        lo_writer = NEW zcl_hithub_object_writer( mo_objects ).
        CLEAR ls_object.
        ls_object-key-repository_id = ls_repository-id.
        ls_object-key-algorithm = 'sha1'.
        ls_object-key-oid = lv_blob_oid.
        ls_object-type = 'blob'.
        ls_object-size = xstrlen( lv_readme_payload ).
        ls_object-payload = lv_readme_payload.
        IF lo_writer->write( ls_object ) = abap_false.
          mo_transaction->rollback( ).
          rs_result-reason = 'initial README could not be persisted'.
          RETURN.
        ENDIF.
        CLEAR ls_object.
        ls_object-key-repository_id = ls_repository-id.
        ls_object-key-algorithm = 'sha1'.
        ls_object-key-oid = lv_tree_oid.
        ls_object-type = 'tree'.
        ls_object-size = xstrlen( lv_tree_payload ).
        ls_object-payload = lv_tree_payload.
        IF lo_writer->write( ls_object ) = abap_false.
          mo_transaction->rollback( ).
          rs_result-reason = 'initial README could not be persisted'.
          RETURN.
        ENDIF.
        CLEAR ls_object.
        ls_object-key-repository_id = ls_repository-id.
        ls_object-key-algorithm = 'sha1'.
        ls_object-key-oid = lv_commit_oid.
        ls_object-type = 'commit'.
        ls_object-size = xstrlen( lv_commit_payload ).
        ls_object-payload = lv_commit_payload.
        IF lo_writer->write( ls_object ) = abap_false.
          mo_transaction->rollback( ).
          rs_result-reason = 'initial README could not be persisted'.
          RETURN.
        ENDIF.

        ls_reference-repository_id = ls_repository-id.
        ls_reference-name = lv_default_branch.
        ls_reference-algorithm = 'sha1'.
        ls_reference-oid = lv_commit_oid.

        mo_metadata->save_repository( ls_repository ).
        lv_ref_version = mo_metadata->create_reference( ls_reference ).
        IF lv_ref_version IS INITIAL.
          mo_transaction->rollback( ).
          rs_result-reason = 'initial README could not be persisted'.
          RETURN.
        ENDIF.
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
    ls_reference-version = lv_ref_version.
    rs_result-success = abap_true.
    rs_result-repository = ls_repository.
  ENDMETHOD.

ENDCLASS.
