CLASS ltcl_file_editor DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_author TYPE string VALUE 'Alice <alice@example.test> 100 +0000'.

    CLASS-DATA gv_sequence TYPE i.

    DATA mo_metadata TYPE REF TO zcl_hithub_local_meta_store.
    DATA mo_objects TYPE REF TO zcl_hithub_local_object_store.
    DATA mo_editor TYPE REF TO zcl_hithub_file_editor.
    DATA mv_repository_id TYPE string.
    DATA mv_head TYPE string.

    METHODS setup.
    METHODS reads_the_seeded_files FOR TESTING RAISING cx_static_check.
    METHODS edits_a_nested_file FOR TESTING RAISING cx_static_check.
    METHODS keeps_sibling_entries FOR TESTING RAISING cx_static_check.
    METHODS rejects_unchanged_content FOR TESTING RAISING cx_static_check.
    METHODS rejects_missing_file FOR TESTING RAISING cx_static_check.
    METHODS rejects_directory_path FOR TESTING RAISING cx_static_check.
    METHODS rejects_stale_head FOR TESTING RAISING cx_static_check.
    METHODS rejects_tag_reference FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_identity FOR TESTING RAISING cx_static_check.

    METHODS seed RAISING cx_static_check.

    METHODS write
      IMPORTING
        iv_type       TYPE string
        iv_payload    TYPE xstring
      RETURNING
        VALUE(rv_oid) TYPE string
      RAISING
        cx_static_check.

    METHODS blob
      IMPORTING
        iv_text       TYPE string
      RETURNING
        VALUE(rv_oid) TYPE string
      RAISING
        cx_static_check.

    METHODS text_at
      IMPORTING
        iv_path        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        cx_static_check.

    CLASS-METHODS entry
      IMPORTING
        iv_mode         TYPE string
        iv_name         TYPE string
        iv_oid          TYPE string
      RETURNING
        VALUE(rs_entry) TYPE zcl_hithub_tree_codec=>ty_entry.
ENDCLASS.

CLASS ltcl_file_editor IMPLEMENTATION.

  METHOD setup.
    mo_metadata = NEW zcl_hithub_local_meta_store( ).
    mo_objects = NEW zcl_hithub_local_object_store( ).
    mo_editor = NEW zcl_hithub_file_editor(
      io_metadata    = mo_metadata
      io_objects     = mo_objects
      io_transaction = NEW zcl_hithub_unit_work( )
      io_lock        = NEW zcl_hithub_local_repo_lock( ) ).
    " Each test seeds identical objects, so every one needs its own repository.
    gv_sequence = gv_sequence + 1.
    mv_repository_id = |editor-{ gv_sequence }|.
  ENDMETHOD.

  METHOD entry.
    rs_entry-mode = iv_mode.
    rs_entry-name = iv_name.
    rs_entry-oid = zcl_hithub_object_id=>to_bytes( iv_oid ).
    " rebuild( ) turns these bytes back into a string to address the child
    " object, so a lossy conversion here breaks every edit below.
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( rs_entry-oid )
      exp = 20
      msg = |the oid { iv_oid } of { iv_name } is not 20 bytes| ).
  ENDMETHOD.

  METHOD write.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_read TYPE zif_hithub_object_store=>ty_object.

    rv_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = iv_type iv_payload = iv_payload ).
    ls_object-key-repository_id = mv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = rv_oid.
    ls_object-type = iv_type.
    ls_object-size = xstrlen( iv_payload ).
    ls_object-payload = iv_payload.
    cl_abap_unit_assert=>assert_equals(
      act = strlen( rv_oid )
      exp = 40
      msg = |{ iv_type } did not hash to a 40 character sha1| ).
    " save( ) commits, so a repository left behind by an earlier run would
    " make write( ) refuse the seed as a duplicate.
    cl_abap_unit_assert=>assert_false(
      act = mo_objects->zif_hithub_object_store~contains( ls_object-key )
      msg = |a { iv_type } with oid { rv_oid } is already stored| ).
    cl_abap_unit_assert=>assert_true(
      act = NEW zcl_hithub_object_writer( mo_objects )->write(
        ls_object ) ).
    ls_read = mo_objects->zif_hithub_object_store~read( ls_object-key ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-type
      exp = iv_type
      msg = |the stored { iv_type } does not read back as a { iv_type }| ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-payload
      exp = iv_payload
      msg = |the stored { iv_type } payload does not read back unchanged| ).
  ENDMETHOD.

  METHOD blob.
    rv_oid = write(
      iv_type = 'blob' iv_payload = cl_abap_codepage=>convert_to( iv_text ) ).
  ENDMETHOD.

  METHOD seed.
    DATA lt_docs TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_src TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_root TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    APPEND entry( iv_mode = '100644' iv_name = 'guide.md'
      iv_oid = blob( |guide{ cl_abap_char_utilities=>newline }| ) ) TO lt_docs.
    DATA(lv_docs) = write(
      iv_type = 'tree' iv_payload = zcl_hithub_tree_codec=>encode( lt_docs ) ).

    APPEND entry( iv_mode = '100644' iv_name = 'app.abap'
      iv_oid = blob( |old line{ cl_abap_char_utilities=>newline }| ) ) TO lt_src.
    APPEND entry( iv_mode = '100644' iv_name = 'util.abap'
      iv_oid = blob( |helper{ cl_abap_char_utilities=>newline }| ) ) TO lt_src.
    APPEND entry( iv_mode = '040000' iv_name = 'docs'
      iv_oid = lv_docs ) TO lt_src.
    DATA(lv_src) = write(
      iv_type = 'tree' iv_payload = zcl_hithub_tree_codec=>encode( lt_src ) ).

    APPEND entry( iv_mode = '100644' iv_name = 'README.md'
      iv_oid = blob( |readme{ cl_abap_char_utilities=>newline }| ) ) TO lt_root.
    APPEND entry( iv_mode = '040000' iv_name = 'src'
      iv_oid = lv_src ) TO lt_root.
    DATA(lv_root) = write(
      iv_type = 'tree' iv_payload = zcl_hithub_tree_codec=>encode( lt_root ) ).

    ls_commit-tree = lv_root.
    ls_commit-author = c_author.
    ls_commit-committer = c_author.
    ls_commit-message = 'Initial commit'.
    mv_head = write(
      iv_type    = 'commit'
      iv_payload = zcl_hithub_commit_codec=>encode( ls_commit ) ).

    ls_reference-repository_id = mv_repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = mv_head.
    mo_metadata->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 0 ).
  ENDMETHOD.

  METHOD text_at.
    DATA(lo_contents) = NEW zcl_hithub_contents_service(
      io_metadata = mo_metadata io_objects = mo_objects ).
    DATA(ls_object) = lo_contents->read(
      iv_repository_id = mv_repository_id
      iv_ref           = 'refs/heads/main'
      iv_path          = iv_path ).
    IF ls_object-key-oid IS INITIAL.
      RETURN.
    ENDIF.
    rv_text = cl_abap_codepage=>convert_from( ls_object-payload ).
  ENDMETHOD.

  METHOD reads_the_seeded_files.
    " save( ) refuses with 'file was not found on this branch' when the
    " contents service cannot walk the tree, which reads the same as a
    " genuinely missing file. Check the plain read on its own first.
    seed( ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'README.md' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/app.abap' )
      exp = |old line{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/util.abap' )
      exp = |helper{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/docs/guide.md' )
      exp = |guide{ cl_abap_char_utilities=>newline }| ).
  ENDMETHOD.

  METHOD edits_a_nested_file.
    seed( ).
    " The editor can only rewrite a file it can read first.
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/docs/guide.md' )
      exp = |guide{ cl_abap_char_utilities=>newline }| ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'main'
      iv_path              = 'src/docs/guide.md'
      iv_content           = |rewritten{ cl_abap_char_utilities=>newline }|
      iv_message           = 'Update the guide'
      iv_author            = c_author
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_initial(
      act = ls_result-reason
      msg = 'the editor refused the edit' ).
    cl_abap_unit_assert=>assert_true( act = ls_result-success ).
    cl_abap_unit_assert=>assert_differs(
      act = ls_result-commit_oid
      exp = mv_head ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/docs/guide.md' )
      exp = |rewritten{ cl_abap_char_utilities=>newline }| ).

    " The branch advances to a commit whose only parent is the old head.
    DATA(lo_commits) = NEW zcl_hithub_commit_service(
      io_metadata = mo_metadata io_objects = mo_objects ).
    DATA(ls_commit) = lo_commits->read(
      iv_repository_id = mv_repository_id
      iv_algorithm     = 'sha1'
      iv_oid           = ls_result-commit_oid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_commit-message
      exp = 'Update the guide' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_commit-parents )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_commit-parents[ 1 ]
      exp = mv_head ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_commit-tree
      exp = ls_result-tree_oid ).
  ENDMETHOD.

  METHOD keeps_sibling_entries.
    seed( ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/app.abap' )
      exp = |old line{ cl_abap_char_utilities=>newline }| ).
    DATA(ls_rewrite) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'refs/heads/main'
      iv_path              = 'src/app.abap'
      iv_content           = |new line{ cl_abap_char_utilities=>newline }|
      iv_message           = 'Rewrite app'
      iv_author            = c_author
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_initial(
      act = ls_rewrite-reason
      msg = 'the editor refused the edit' ).
    cl_abap_unit_assert=>assert_true( act = ls_rewrite-success ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/app.abap' )
      exp = |new line{ cl_abap_char_utilities=>newline }| ).
    " Siblings at every rewritten level survive untouched.
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/util.abap' )
      exp = |helper{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'src/docs/guide.md' )
      exp = |guide{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'README.md' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
  ENDMETHOD.

  METHOD rejects_unchanged_content.
    seed( ).
    " 'file was not found on this branch' here would mean the editor never
    " reached the content comparison at all.
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'README.md' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'main'
      iv_path              = 'README.md'
      iv_content           = |readme{ cl_abap_char_utilities=>newline }|
      iv_message           = 'No change'
      iv_author            = c_author
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'file content is unchanged' ).
  ENDMETHOD.

  METHOD rejects_missing_file.
    seed( ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'main'
      iv_path              = 'src/absent.abap'
      iv_content           = 'anything'
      iv_message           = 'Create by editing'
      iv_author            = c_author
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'file was not found on this branch' ).
  ENDMETHOD.

  METHOD rejects_directory_path.
    seed( ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'main'
      iv_path              = 'src/docs'
      iv_content           = 'anything'
      iv_message           = 'Edit a directory'
      iv_author            = c_author
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'file was not found on this branch' ).
  ENDMETHOD.

  METHOD rejects_stale_head.
    seed( ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'main'
      iv_path              = 'README.md'
      iv_content           = 'anything'
      iv_message           = 'Stale edit'
      iv_author            = c_author
      iv_expected_head_oid = '1111111111111111111111111111111111111111' ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_true( act = ls_result-stale ).
    cl_abap_unit_assert=>assert_equals(
      act = text_at( 'README.md' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
  ENDMETHOD.

  METHOD rejects_tag_reference.
    seed( ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'refs/tags/v1'
      iv_path              = 'README.md'
      iv_content           = 'anything'
      iv_message           = 'Edit a tag'
      iv_author            = c_author
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'only branches can be edited' ).
  ENDMETHOD.

  METHOD rejects_invalid_identity.
    seed( ).
    DATA(ls_result) = mo_editor->save(
      iv_repository_id     = mv_repository_id
      iv_ref               = 'main'
      iv_path              = 'README.md'
      iv_content           = 'anything'
      iv_message           = 'Bad identity'
      iv_author            = 'not an identity'
      iv_expected_head_oid = mv_head ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'commit identity is invalid' ).
  ENDMETHOD.

ENDCLASS.
