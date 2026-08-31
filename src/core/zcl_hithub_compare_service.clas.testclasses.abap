CLASS ltcl_compare_service DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zcl_hithub_local_meta_store.
    DATA mo_objects TYPE REF TO zcl_hithub_local_object_store.
    DATA mo_writer TYPE REF TO zcl_hithub_object_writer.
    DATA mv_repository_id TYPE string.

    METHODS setup.
    METHODS diffs_nested_trees FOR TESTING RAISING cx_static_check.
    METHODS diffs_from_the_merge_base FOR TESTING RAISING cx_static_check.
    METHODS reports_binary_files FOR TESTING RAISING cx_static_check.
    METHODS rejects_unknown_reference FOR TESTING RAISING cx_static_check.

    METHODS store
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

    METHODS tree
      IMPORTING
        it_entries    TYPE zcl_hithub_tree_codec=>ty_entries
      RETURNING
        VALUE(rv_oid) TYPE string
      RAISING
        cx_static_check.

    METHODS commit
      IMPORTING
        iv_tree       TYPE string
        iv_parent     TYPE string OPTIONAL
        iv_message    TYPE string
      RETURNING
        VALUE(rv_oid) TYPE string
      RAISING
        cx_static_check.

    METHODS reference
      IMPORTING
        iv_name TYPE string
        iv_oid  TYPE string
      RAISING
        cx_static_check.

    METHODS compare
      IMPORTING
        iv_base              TYPE string
        iv_head              TYPE string
      RETURNING
        VALUE(rs_comparison) TYPE zcl_hithub_compare_service=>ty_comparison
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

CLASS ltcl_compare_service IMPLEMENTATION.

  METHOD setup.
    mo_metadata = NEW zcl_hithub_local_meta_store( ).
    mo_objects = NEW zcl_hithub_local_object_store( ).
    mo_writer = NEW zcl_hithub_object_writer( mo_objects ).
    mv_repository_id = |compare-{ sy-uzeit }-{ sy-index }|.
  ENDMETHOD.

  METHOD store.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    rv_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = iv_type iv_payload = iv_payload ).
    ls_object-key-repository_id = mv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = rv_oid.
    ls_object-type = iv_type.
    ls_object-size = xstrlen( iv_payload ).
    ls_object-payload = iv_payload.
    ASSERT mo_writer->write( ls_object ) = abap_true.
  ENDMETHOD.

  METHOD blob.
    rv_oid = store(
      iv_type    = 'blob'
      iv_payload = cl_abap_codepage=>convert_to( iv_text ) ).
  ENDMETHOD.

  METHOD tree.
    rv_oid = store(
      iv_type    = 'tree'
      iv_payload = zcl_hithub_tree_codec=>encode( it_entries ) ).
  ENDMETHOD.

  METHOD commit.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.

    ls_commit-tree = iv_tree.
    IF iv_parent IS NOT INITIAL.
      APPEND iv_parent TO ls_commit-parents.
    ENDIF.
    ls_commit-author = 'Tester <tester@example.com> 0 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = iv_message.
    rv_oid = store(
      iv_type    = 'commit'
      iv_payload = zcl_hithub_commit_codec=>encode( ls_commit ) ).
  ENDMETHOD.

  METHOD reference.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    ls_reference-repository_id = mv_repository_id.
    ls_reference-name = iv_name.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = iv_oid.
    mo_metadata->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 0 ).
  ENDMETHOD.

  METHOD compare.
    DATA(lo_service) = NEW zcl_hithub_compare_service(
      io_metadata = mo_metadata io_objects = mo_objects ).
    rs_comparison = lo_service->compare(
      iv_repository_id = mv_repository_id
      iv_base          = iv_base
      iv_head          = iv_head ).
  ENDMETHOD.

  METHOD entry.
    rs_entry-mode = iv_mode.
    rs_entry-name = iv_name.
    rs_entry-oid = CONV xstring( iv_oid ).
  ENDMETHOD.

  METHOD diffs_nested_trees.
    DATA lt_base_root TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_head_root TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_base_src TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_head_src TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_file TYPE zcl_hithub_compare_service=>ty_file.

    DATA(lv_readme) = blob( |one{ cl_abap_char_utilities=>newline }| ).
    DATA(lv_gone) = blob( |gone{ cl_abap_char_utilities=>newline }| ).
    DATA(lv_old_code) = blob( |alpha{ cl_abap_char_utilities=>newline }| ).
    DATA(lv_new_code) = blob( |beta{ cl_abap_char_utilities=>newline }| ).
    DATA(lv_added) = blob( |fresh{ cl_abap_char_utilities=>newline }| ).

    APPEND entry( iv_mode = '100644' iv_name = 'code.txt'
      iv_oid = lv_old_code ) TO lt_base_src.
    APPEND entry( iv_mode = '100644' iv_name = 'code.txt'
      iv_oid = lv_new_code ) TO lt_head_src.
    APPEND entry( iv_mode = '100644' iv_name = 'added.txt'
      iv_oid = lv_added ) TO lt_head_src.
    DATA(lv_base_src) = tree( lt_base_src ).
    DATA(lv_head_src) = tree( lt_head_src ).

    APPEND entry( iv_mode = '100644' iv_name = 'README'
      iv_oid = lv_readme ) TO lt_base_root.
    APPEND entry( iv_mode = '100644' iv_name = 'gone.txt'
      iv_oid = lv_gone ) TO lt_base_root.
    APPEND entry( iv_mode = '040000' iv_name = 'src'
      iv_oid = lv_base_src ) TO lt_base_root.
    APPEND entry( iv_mode = '100644' iv_name = 'README'
      iv_oid = lv_readme ) TO lt_head_root.
    APPEND entry( iv_mode = '040000' iv_name = 'src'
      iv_oid = lv_head_src ) TO lt_head_root.

    DATA(lv_base_commit) = commit(
      iv_tree = tree( lt_base_root ) iv_message = 'base' ).
    DATA(lv_head_commit) = commit(
      iv_tree = tree( lt_head_root ) iv_parent = lv_base_commit
      iv_message = 'head' ).
    reference( iv_name = 'refs/heads/main' iv_oid = lv_base_commit ).
    reference( iv_name = 'refs/heads/topic' iv_oid = lv_head_commit ).

    DATA(ls_comparison) = compare( iv_base = 'main' iv_head = 'topic' ).
    ASSERT ls_comparison-found = abap_true.
    ASSERT ls_comparison-merge_base_oid = lv_base_commit.
    ASSERT ls_comparison-summary-total = 3.
    ASSERT ls_comparison-summary-added = 1.
    ASSERT ls_comparison-summary-modified = 1.
    ASSERT ls_comparison-summary-deleted = 1.
    ASSERT ls_comparison-additions = 2.
    ASSERT ls_comparison-deletions = 2.

    READ TABLE ls_comparison-files WITH KEY path = 'src/code.txt'
      INTO ls_file.
    ASSERT sy-subrc = 0.
    ASSERT ls_file-status = 'modified'.
    ASSERT ls_file-patch CS '--- a/src/code.txt'.
    ASSERT ls_file-patch CS '-alpha'.
    ASSERT ls_file-patch CS '+beta'.
    READ TABLE ls_comparison-files WITH KEY path = 'src/added.txt'
      INTO ls_file.
    ASSERT sy-subrc = 0.
    ASSERT ls_file-status = 'added'.
    ASSERT ls_file-patch CS '--- /dev/null'.
    READ TABLE ls_comparison-files WITH KEY path = 'gone.txt' INTO ls_file.
    ASSERT sy-subrc = 0.
    ASSERT ls_file-status = 'deleted'.
    ASSERT ls_file-patch CS '+++ /dev/null'.
    READ TABLE ls_comparison-files WITH KEY path = 'README' INTO ls_file.
    ASSERT sy-subrc <> 0.
  ENDMETHOD.

  METHOD diffs_from_the_merge_base.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_file TYPE zcl_hithub_compare_service=>ty_file.

    APPEND entry( iv_mode = '100644' iv_name = 'file.txt'
      iv_oid = blob( |root{ cl_abap_char_utilities=>newline }| ) ) TO lt_entries.
    DATA(lv_root) = commit( iv_tree = tree( lt_entries ) iv_message = 'root' ).

    CLEAR lt_entries.
    APPEND entry( iv_mode = '100644' iv_name = 'file.txt'
      iv_oid = blob( |base{ cl_abap_char_utilities=>newline }| ) ) TO lt_entries.
    DATA(lv_base) = commit(
      iv_tree = tree( lt_entries ) iv_parent = lv_root iv_message = 'base' ).

    CLEAR lt_entries.
    APPEND entry( iv_mode = '100644' iv_name = 'file.txt'
      iv_oid = blob( |head{ cl_abap_char_utilities=>newline }| ) ) TO lt_entries.
    DATA(lv_head) = commit(
      iv_tree = tree( lt_entries ) iv_parent = lv_root iv_message = 'head' ).

    reference( iv_name = 'refs/heads/main' iv_oid = lv_base ).
    reference( iv_name = 'refs/heads/topic' iv_oid = lv_head ).

    DATA(ls_comparison) = compare( iv_base = 'main' iv_head = 'topic' ).
    ASSERT ls_comparison-found = abap_true.
    ASSERT ls_comparison-merge_base_oid = lv_root.
    ASSERT ls_comparison-base_oid = lv_base.
    ASSERT lines( ls_comparison-files ) = 1.
    READ TABLE ls_comparison-files INDEX 1 INTO ls_file.
    ASSERT ls_file-patch CS '-root'.
    ASSERT ls_file-patch CS '+head'.
  ENDMETHOD.

  METHOD reports_binary_files.
    DATA lt_base TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_head TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_file TYPE zcl_hithub_compare_service=>ty_file.

    APPEND entry( iv_mode = '100644' iv_name = 'icon.bin'
      iv_oid = store( iv_type = 'blob' iv_payload = '00010203' ) ) TO lt_base.
    APPEND entry( iv_mode = '100644' iv_name = 'icon.bin'
      iv_oid = store( iv_type = 'blob' iv_payload = '00040506' ) ) TO lt_head.
    DATA(lv_base) = commit( iv_tree = tree( lt_base ) iv_message = 'base' ).
    DATA(lv_head) = commit(
      iv_tree = tree( lt_head ) iv_parent = lv_base iv_message = 'head' ).
    reference( iv_name = 'refs/heads/main' iv_oid = lv_base ).
    reference( iv_name = 'refs/heads/topic' iv_oid = lv_head ).

    DATA(ls_comparison) = compare( iv_base = 'main' iv_head = 'topic' ).
    ASSERT lines( ls_comparison-files ) = 1.
    READ TABLE ls_comparison-files INDEX 1 INTO ls_file.
    ASSERT ls_file-binary = abap_true.
    ASSERT ls_file-additions = 0.
    ASSERT ls_file-deletions = 0.
    ASSERT ls_file-patch CS 'Binary files differ'.
  ENDMETHOD.

  METHOD rejects_unknown_reference.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.

    APPEND entry( iv_mode = '100644' iv_name = 'file.txt'
      iv_oid = blob( |only{ cl_abap_char_utilities=>newline }| ) ) TO lt_entries.
    reference(
      iv_name = 'refs/heads/main'
      iv_oid  = commit( iv_tree = tree( lt_entries ) iv_message = 'only' ) ).

    DATA(ls_comparison) = compare( iv_base = 'main' iv_head = 'absent' ).
    ASSERT ls_comparison-found = abap_false.
    ASSERT ls_comparison-reason = 'head reference was not found'.
  ENDMETHOD.

ENDCLASS.
