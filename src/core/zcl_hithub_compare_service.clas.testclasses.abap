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
    " write( ) refuses an object that is already stored, so tell a genuine
    " write failure apart from two fixtures colliding on one oid.
    cl_abap_unit_assert=>assert_false(
      act = mo_objects->zif_hithub_object_store~contains( ls_object-key )
      msg = |a { iv_type } with oid { rv_oid } is already stored| ).
    cl_abap_unit_assert=>assert_true(
      act = mo_writer->write( ls_object )
      msg = |the { iv_type } object could not be written| ).
    " compare( ) resolves everything through the store, so a payload that
    " does not come back unchanged breaks every assertion further down.
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
    DATA ls_decoded TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA lv_payload TYPE xstring.

    ls_commit-tree = iv_tree.
    IF iv_parent IS NOT INITIAL.
      APPEND iv_parent TO ls_commit-parents.
    ENDIF.
    ls_commit-author = 'Tester <tester@example.com> 0 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = iv_message.
    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).

    " The merge base walk reads the tree and the parents back out of the
    " payload, so check the codec before compare( ) depends on it.
    ls_decoded = zcl_hithub_commit_codec=>decode( lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-tree
      exp = iv_tree
      msg = |commit { iv_message } lost its tree in the codec| ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_decoded-parents )
      exp = lines( ls_commit-parents )
      msg = |commit { iv_message } lost its parents in the codec| ).

    rv_oid = store( iv_type = 'commit' iv_payload = lv_payload ).
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
    " Two trees that differ only here must not collapse onto one payload.
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( rs_entry-oid )
      exp = 20
      msg = |the oid { iv_oid } of { iv_name } is not 20 bytes| ).
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
    cl_abap_unit_assert=>assert_true( act = ls_comparison-found ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-base_oid
      exp = lv_base_commit
      msg = 'main did not resolve to the base commit' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-head_oid
      exp = lv_head_commit
      msg = 'topic did not resolve to the head commit' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-merge_base_oid
      exp = lv_base_commit ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-summary-total
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-summary-added
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-summary-modified
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-summary-deleted
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_comparison-additions exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_comparison-deletions exp = 2 ).

    READ TABLE ls_comparison-files WITH KEY path = 'src/code.txt'
      INTO ls_file.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( act = ls_file-status exp = 'modified' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '--- a/src/code.txt' ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '-alpha' ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '+beta' ) ).
    READ TABLE ls_comparison-files WITH KEY path = 'src/added.txt'
      INTO ls_file.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( act = ls_file-status exp = 'added' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '--- /dev/null' ) ).
    READ TABLE ls_comparison-files WITH KEY path = 'gone.txt' INTO ls_file.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( act = ls_file-status exp = 'deleted' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '+++ /dev/null' ) ).
    READ TABLE ls_comparison-files WITH KEY path = 'README' INTO ls_file.
    cl_abap_unit_assert=>assert_differs( act = sy-subrc exp = 0 ).
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
    cl_abap_unit_assert=>assert_true( act = ls_comparison-found ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-merge_base_oid
      exp = lv_root ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-base_oid
      exp = lv_base ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_comparison-files )
      exp = 1 ).
    READ TABLE ls_comparison-files INDEX 1 INTO ls_file.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '-root' ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS '+head' ) ).
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
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_comparison-files )
      exp = 1 ).
    READ TABLE ls_comparison-files INDEX 1 INTO ls_file.
    cl_abap_unit_assert=>assert_true( act = ls_file-binary ).
    cl_abap_unit_assert=>assert_equals( act = ls_file-additions exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = ls_file-deletions exp = 0 ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_file-patch CS 'Binary files differ' ) ).
  ENDMETHOD.

  METHOD rejects_unknown_reference.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.

    APPEND entry( iv_mode = '100644' iv_name = 'file.txt'
      iv_oid = blob( |only{ cl_abap_char_utilities=>newline }| ) ) TO lt_entries.
    reference(
      iv_name = 'refs/heads/main'
      iv_oid  = commit( iv_tree = tree( lt_entries ) iv_message = 'only' ) ).

    DATA(ls_comparison) = compare( iv_base = 'main' iv_head = 'absent' ).
    cl_abap_unit_assert=>assert_false( act = ls_comparison-found ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_comparison-reason
      exp = 'head reference was not found' ).
  ENDMETHOD.

ENDCLASS.
