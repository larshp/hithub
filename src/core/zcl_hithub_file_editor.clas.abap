CLASS zcl_hithub_file_editor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_max_content_size TYPE i VALUE 1048576.
    CONSTANTS c_max_depth TYPE i VALUE 32.
    CONSTANTS c_tree_mode TYPE string VALUE '040000'.

    TYPES:
      BEGIN OF ty_result,
        success    TYPE abap_bool,
        reason     TYPE string,
        stale      TYPE abap_bool,
        ref        TYPE string,
        commit_oid TYPE string,
        tree_oid   TYPE string,
        blob_oid   TYPE string,
      END OF ty_result.

    METHODS constructor
      IMPORTING
        io_metadata    TYPE REF TO zif_hithub_metadata_store
        io_objects     TYPE REF TO zif_hithub_object_store
        io_transaction TYPE REF TO zif_hithub_transaction
        io_lock        TYPE REF TO zif_hithub_repository_lock OPTIONAL.

    "! Replaces the text of an existing file on a branch with one commit,
    "! rewriting every tree between the repository root and the file.
    METHODS save
      IMPORTING
        iv_repository_id     TYPE string
        iv_ref               TYPE string
        iv_path              TYPE string
        iv_content           TYPE string
        iv_message           TYPE string
        iv_author            TYPE string
        iv_expected_head_oid TYPE string
        iv_owner             TYPE string DEFAULT 'file-editor'
      RETURNING
        VALUE(rs_result)     TYPE ty_result
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    TYPES ty_parts TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_objects TYPE REF TO zif_hithub_object_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    DATA mo_lock TYPE REF TO zif_hithub_repository_lock.

    METHODS rebuild
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        iv_tree_oid      TYPE string
        it_parts         TYPE ty_parts
        iv_index         TYPE i
        iv_blob_oid      TYPE string
      RETURNING
        VALUE(rv_oid)    TYPE string
      RAISING
        cx_static_check.

    METHODS store
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        iv_type          TYPE string
        iv_payload       TYPE xstring
      RETURNING
        VALUE(rv_oid)    TYPE string
      RAISING
        cx_static_check.

    CLASS-METHODS split_path
      IMPORTING
        iv_path         TYPE string
      RETURNING
        VALUE(rt_parts) TYPE ty_parts.
ENDCLASS.

CLASS zcl_hithub_file_editor IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
    mo_transaction = io_transaction.
    mo_lock = io_lock.
  ENDMETHOD.

  METHOD split_path.
    CLEAR rt_parts.
    IF iv_path IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT iv_path AT '/' INTO TABLE rt_parts.
    DELETE rt_parts WHERE table_line IS INITIAL.
  ENDMETHOD.

  METHOD store.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lo_writer TYPE REF TO zcl_hithub_object_writer.

    rv_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = iv_algorithm iv_type = iv_type iv_payload = iv_payload ).
    ls_object-key-repository_id = iv_repository_id.
    ls_object-key-algorithm = iv_algorithm.
    ls_object-key-oid = rv_oid.
    ls_object-type = iv_type.
    ls_object-size = xstrlen( iv_payload ).
    ls_object-payload = iv_payload.
    IF mo_objects->contains( ls_object-key ) = abap_true.
      RETURN.
    ENDIF.
    lo_writer = NEW zcl_hithub_object_writer( mo_objects ).
    IF lo_writer->write( ls_object ) = abap_false.
      CLEAR rv_oid.
    ENDIF.
  ENDMETHOD.

  METHOD rebuild.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA lv_part TYPE string.
    DATA lv_child TYPE string.
    DATA lv_oid_length TYPE i.
    DATA lv_index TYPE i.

    CLEAR rv_oid.
    IF iv_index > lines( it_parts ) OR iv_index > c_max_depth.
      RETURN.
    ENDIF.
    READ TABLE it_parts INDEX iv_index INTO lv_part.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ls_key-repository_id = iv_repository_id.
    ls_key-algorithm = iv_algorithm.
    ls_key-oid = iv_tree_oid.
    ls_object = mo_objects->read( ls_key ).
    IF ls_object-type <> 'tree'.
      RETURN.
    ENDIF.
    lv_oid_length = COND i( WHEN iv_algorithm = 'sha256' THEN 32 ELSE 20 ).
    lt_entries = zcl_hithub_tree_codec=>decode(
      iv_payload = ls_object-payload iv_oid_length = lv_oid_length ).
    READ TABLE lt_entries WITH KEY name = lv_part INTO ls_entry.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_index = sy-tabix.
    IF iv_index = lines( it_parts ).
      IF ls_entry-mode = c_tree_mode.
        RETURN.
      ENDIF.
      ls_entry-oid = CONV xstring( iv_blob_oid ).
    ELSE.
      IF ls_entry-mode <> c_tree_mode.
        RETURN.
      ENDIF.
      lv_child = rebuild(
        iv_repository_id = iv_repository_id
        iv_algorithm     = iv_algorithm
        iv_tree_oid      = CONV string( ls_entry-oid )
        it_parts         = it_parts
        iv_index         = iv_index + 1
        iv_blob_oid      = iv_blob_oid ).
      IF lv_child IS INITIAL.
        RETURN.
      ENDIF.
      ls_entry-oid = CONV xstring( lv_child ).
    ENDIF.
    MODIFY lt_entries INDEX lv_index FROM ls_entry.
    rv_oid = store(
      iv_repository_id = iv_repository_id
      iv_algorithm     = iv_algorithm
      iv_type          = 'tree'
      iv_payload       = zcl_hithub_tree_codec=>encode( lt_entries ) ).
  ENDMETHOD.

  METHOD save.
    DATA lv_ref TYPE string.
    DATA lt_parts TYPE ty_parts.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_update TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_head TYPE zif_hithub_object_store=>ty_object.
    DATA ls_head_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_head_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_existing TYPE zif_hithub_object_store=>ty_object.
    DATA lo_contents TYPE REF TO zcl_hithub_contents_service.
    DATA lv_payload TYPE xstring.
    DATA lv_blob_oid TYPE string.
    DATA lv_tree_oid TYPE string.
    DATA lv_commit_oid TYPE string.
    DATA lv_locked TYPE abap_bool.
    DATA lv_version TYPE int8.

    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_objects IS INITIAL
        OR mo_transaction IS INITIAL.
      rs_result-reason = 'file editor dependencies are incomplete'.
      RETURN.
    ENDIF.
    IF iv_repository_id IS INITIAL OR iv_path IS INITIAL
        OR iv_message IS INITIAL.
      rs_result-reason = 'repository, path, and message are required'.
      RETURN.
    ENDIF.
    IF strlen( iv_content ) > c_max_content_size.
      rs_result-reason = 'file content is too large to edit in the browser'.
      RETURN.
    ENDIF.
    IF zcl_hithub_identity=>is_valid( iv_author ) = abap_false.
      rs_result-reason = 'commit identity is invalid'.
      RETURN.
    ENDIF.
    lt_parts = split_path( iv_path ).
    IF lines( lt_parts ) = 0 OR lines( lt_parts ) > c_max_depth.
      rs_result-reason = 'file path is invalid'.
      RETURN.
    ENDIF.

    lv_ref = iv_ref.
    IF lv_ref IS INITIAL.
      rs_result-reason = 'branch is required'.
      RETURN.
    ENDIF.
    IF lv_ref NP 'refs/*'.
      lv_ref = |refs/heads/{ lv_ref }|.
    ENDIF.
    IF lv_ref NP 'refs/heads/*'.
      rs_result-reason = 'only branches can be edited'.
      RETURN.
    ENDIF.
    rs_result-ref = lv_ref.

    IF mo_lock IS NOT INITIAL.
      lv_locked = mo_lock->acquire(
        iv_repository_id = iv_repository_id iv_owner = iv_owner ).
      IF lv_locked = abap_false.
        rs_result-reason = 'repository is locked'.
        RETURN.
      ENDIF.
    ENDIF.

    ls_reference = mo_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = lv_ref ).
    IF ls_reference-oid IS INITIAL.
      rs_result-reason = 'branch was not found'.
      IF lv_locked = abap_true.
        mo_lock->release(
          iv_repository_id = iv_repository_id iv_owner = iv_owner ).
      ENDIF.
      RETURN.
    ENDIF.
    IF iv_expected_head_oid IS NOT INITIAL
        AND iv_expected_head_oid <> ls_reference-oid.
      rs_result-reason = 'the branch moved while the file was being edited'.
      rs_result-stale = abap_true.
      IF lv_locked = abap_true.
        mo_lock->release(
          iv_repository_id = iv_repository_id iv_owner = iv_owner ).
      ENDIF.
      RETURN.
    ENDIF.

    ls_head_key-repository_id = iv_repository_id.
    ls_head_key-algorithm = ls_reference-algorithm.
    ls_head_key-oid = ls_reference-oid.
    ls_head = mo_objects->read( ls_head_key ).
    lo_contents = NEW zcl_hithub_contents_service(
      io_metadata = mo_metadata io_objects = mo_objects ).
    ls_existing = lo_contents->read(
      iv_repository_id = iv_repository_id iv_ref = lv_ref iv_path = iv_path ).
    lv_payload = cl_abap_codepage=>convert_to( iv_content ).
    lv_blob_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = ls_reference-algorithm
      iv_type      = 'blob'
      iv_payload   = lv_payload ).
    IF ls_head-type <> 'commit'.
      rs_result-reason = 'branch head commit could not be read'.
    ELSEIF ls_existing-key-oid IS INITIAL.
      rs_result-reason = 'file was not found on this branch'.
    ELSEIF ls_existing-key-oid = lv_blob_oid.
      rs_result-reason = 'file content is unchanged'.
    ENDIF.
    IF rs_result-reason IS NOT INITIAL.
      IF lv_locked = abap_true.
        mo_lock->release(
          iv_repository_id = iv_repository_id iv_owner = iv_owner ).
      ENDIF.
      RETURN.
    ENDIF.
    ls_head_commit = zcl_hithub_commit_codec=>decode( ls_head-payload ).

    mo_transaction->start( ).
    lv_blob_oid = store(
      iv_repository_id = iv_repository_id
      iv_algorithm     = ls_reference-algorithm
      iv_type          = 'blob'
      iv_payload       = lv_payload ).
    IF lv_blob_oid IS NOT INITIAL.
      lv_tree_oid = rebuild(
        iv_repository_id = iv_repository_id
        iv_algorithm     = ls_reference-algorithm
        iv_tree_oid      = ls_head_commit-tree
        it_parts         = lt_parts
        iv_index         = 1
        iv_blob_oid      = lv_blob_oid ).
    ENDIF.
    IF lv_tree_oid IS INITIAL.
      mo_transaction->rollback( ).
      rs_result-reason = 'the updated tree could not be written'.
      IF lv_locked = abap_true.
        mo_lock->release(
          iv_repository_id = iv_repository_id iv_owner = iv_owner ).
      ENDIF.
      RETURN.
    ENDIF.

    ls_commit-tree = lv_tree_oid.
    APPEND ls_reference-oid TO ls_commit-parents.
    ls_commit-author = iv_author.
    ls_commit-committer = iv_author.
    ls_commit-message = iv_message.
    lv_commit_oid = store(
      iv_repository_id = iv_repository_id
      iv_algorithm     = ls_reference-algorithm
      iv_type          = 'commit'
      iv_payload       = zcl_hithub_commit_codec=>encode( ls_commit ) ).
    IF lv_commit_oid IS INITIAL.
      mo_transaction->rollback( ).
      rs_result-reason = 'the commit could not be written'.
      IF lv_locked = abap_true.
        mo_lock->release(
          iv_repository_id = iv_repository_id iv_owner = iv_owner ).
      ENDIF.
      RETURN.
    ENDIF.

    ls_update = ls_reference.
    ls_update-oid = lv_commit_oid.
    lv_version = mo_metadata->save_reference(
      is_reference        = ls_update
      iv_expected_version = ls_reference-version ).
    IF lv_version IS INITIAL.
      mo_transaction->rollback( ).
      rs_result-reason = 'the branch moved while the file was being edited'.
      rs_result-stale = abap_true.
    ELSE.
      mo_transaction->commit( ).
      rs_result-success = abap_true.
      rs_result-commit_oid = lv_commit_oid.
      rs_result-tree_oid = lv_tree_oid.
      rs_result-blob_oid = lv_blob_oid.
    ENDIF.
    IF lv_locked = abap_true.
      mo_lock->release(
        iv_repository_id = iv_repository_id iv_owner = iv_owner ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
