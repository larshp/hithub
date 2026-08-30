CLASS zcl_hithub_compare_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_max_blob_size TYPE i VALUE 262144.

    TYPES:
      BEGIN OF ty_file,
        path      TYPE string,
        status    TYPE string,
        old_oid   TYPE string,
        new_oid   TYPE string,
        additions TYPE i,
        deletions TYPE i,
        binary    TYPE abap_bool,
        truncated TYPE abap_bool,
        patch     TYPE string,
      END OF ty_file,
      ty_files TYPE STANDARD TABLE OF ty_file WITH DEFAULT KEY,
      BEGIN OF ty_comparison,
        found          TYPE abap_bool,
        reason         TYPE string,
        base_ref       TYPE string,
        head_ref       TYPE string,
        base_oid       TYPE string,
        head_oid       TYPE string,
        merge_base_oid TYPE string,
        additions      TYPE i,
        deletions      TYPE i,
        summary        TYPE zcl_hithub_patch_summary=>ty_summary,
        files          TYPE ty_files,
      END OF ty_comparison.

    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_objects  TYPE REF TO zif_hithub_object_store.

    METHODS compare
      IMPORTING
        iv_repository_id     TYPE string
        iv_base              TYPE string
        iv_head              TYPE string
      RETURNING
        VALUE(rs_comparison) TYPE ty_comparison
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    CONSTANTS c_history_limit TYPE i VALUE 500.
    CONSTANTS c_tree_depth TYPE i VALUE 32.
    CONSTANTS c_binary_probe TYPE i VALUE 8000.

    TYPES:
      BEGIN OF ty_blob,
        found  TYPE abap_bool,
        binary TYPE abap_bool,
        large  TYPE abap_bool,
        text   TYPE string,
      END OF ty_blob.

    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_objects TYPE REF TO zif_hithub_object_store.

    METHODS resolve
      IMPORTING
        iv_repository_id TYPE string
        iv_reference     TYPE string
      RETURNING
        VALUE(rs_key)    TYPE zif_hithub_object_store=>ty_object_key
      RAISING
        cx_static_check.

    METHODS tree_of
      IMPORTING
        is_commit      TYPE zif_hithub_object_store=>ty_object_key
      RETURNING
        VALUE(rv_tree) TYPE string
      RAISING
        cx_static_check.

    METHODS flatten
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        iv_tree_oid      TYPE string
        iv_prefix        TYPE string
        iv_depth         TYPE i
      CHANGING
        ct_files         TYPE zcl_hithub_changed_files=>ty_files
      RAISING
        cx_static_check.

    METHODS collect_history
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        iv_oid           TYPE string
      CHANGING
        ct_commits       TYPE zcl_hithub_merge_base=>ty_commits
      RAISING
        cx_static_check.

    METHODS blob
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        iv_oid           TYPE string
      RETURNING
        VALUE(rs_blob)   TYPE ty_blob
      RAISING
        cx_static_check.

    CLASS-METHODS is_binary
      IMPORTING
        iv_payload       TYPE xstring
      RETURNING
        VALUE(rv_binary) TYPE abap_bool.

    CLASS-METHODS oid_length
      IMPORTING
        iv_algorithm     TYPE string
      RETURNING
        VALUE(rv_length) TYPE i.
ENDCLASS.

CLASS zcl_hithub_compare_service IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
  ENDMETHOD.

  METHOD compare.
    DATA ls_base_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_head_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_diff_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    DATA lt_base_files TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_head_files TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_changes TYPE zcl_hithub_changed_files=>ty_changes.
    DATA ls_change TYPE zcl_hithub_changed_files=>ty_change.
    DATA ls_file TYPE ty_file.
    DATA ls_old_blob TYPE ty_blob.
    DATA ls_new_blob TYPE ty_blob.
    DATA ls_diff TYPE zcl_hithub_unified_diff=>ty_result.
    DATA lv_old_label TYPE string.
    DATA lv_new_label TYPE string.
    DATA lv_base_tree TYPE string.
    DATA lv_head_tree TYPE string.

    CLEAR rs_comparison.
    rs_comparison-base_ref = iv_base.
    rs_comparison-head_ref = iv_head.
    IF mo_metadata IS INITIAL OR mo_objects IS INITIAL
        OR iv_repository_id IS INITIAL
        OR iv_base IS INITIAL OR iv_head IS INITIAL.
      rs_comparison-reason = 'base and head references are required'.
      RETURN.
    ENDIF.

    ls_base_key = resolve(
      iv_repository_id = iv_repository_id iv_reference = iv_base ).
    IF ls_base_key-oid IS INITIAL.
      rs_comparison-reason = 'base reference was not found'.
      RETURN.
    ENDIF.
    ls_head_key = resolve(
      iv_repository_id = iv_repository_id iv_reference = iv_head ).
    IF ls_head_key-oid IS INITIAL.
      rs_comparison-reason = 'head reference was not found'.
      RETURN.
    ENDIF.
    rs_comparison-base_oid = ls_base_key-oid.
    rs_comparison-head_oid = ls_head_key-oid.

    collect_history(
      EXPORTING
        iv_repository_id = iv_repository_id
        iv_algorithm     = ls_base_key-algorithm
        iv_oid           = ls_base_key-oid
      CHANGING
        ct_commits       = lt_commits ).
    collect_history(
      EXPORTING
        iv_repository_id = iv_repository_id
        iv_algorithm     = ls_head_key-algorithm
        iv_oid           = ls_head_key-oid
      CHANGING
        ct_commits       = lt_commits ).
    rs_comparison-merge_base_oid = zcl_hithub_merge_base=>find(
      it_commits = lt_commits
      iv_head_a  = ls_base_key-oid
      iv_head_b  = ls_head_key-oid ).

    ls_diff_key = ls_base_key.
    IF rs_comparison-merge_base_oid IS NOT INITIAL.
      ls_diff_key-oid = rs_comparison-merge_base_oid.
    ENDIF.
    lv_base_tree = tree_of( ls_diff_key ).
    lv_head_tree = tree_of( ls_head_key ).
    IF lv_head_tree IS INITIAL.
      rs_comparison-reason = 'head commit could not be read'.
      RETURN.
    ENDIF.
    rs_comparison-found = abap_true.

    flatten(
      EXPORTING
        iv_repository_id = iv_repository_id
        iv_algorithm     = ls_diff_key-algorithm
        iv_tree_oid      = lv_base_tree
        iv_prefix        = ''
        iv_depth         = 0
      CHANGING
        ct_files         = lt_base_files ).
    flatten(
      EXPORTING
        iv_repository_id = iv_repository_id
        iv_algorithm     = ls_head_key-algorithm
        iv_tree_oid      = lv_head_tree
        iv_prefix        = ''
        iv_depth         = 0
      CHANGING
        ct_files         = lt_head_files ).

    lt_changes = zcl_hithub_changed_files=>calculate(
      it_base = lt_base_files it_head = lt_head_files ).
    rs_comparison-summary = zcl_hithub_patch_summary=>generate( lt_changes ).

    LOOP AT lt_changes INTO ls_change.
      CLEAR: ls_file, ls_old_blob, ls_new_blob, ls_diff.
      ls_file-path = ls_change-path.
      ls_file-status = ls_change-status.
      ls_file-old_oid = ls_change-old_oid.
      ls_file-new_oid = ls_change-new_oid.
      IF ls_change-old_oid IS NOT INITIAL.
        ls_old_blob = blob(
          iv_repository_id = iv_repository_id
          iv_algorithm     = ls_diff_key-algorithm
          iv_oid           = ls_change-old_oid ).
      ENDIF.
      IF ls_change-new_oid IS NOT INITIAL.
        ls_new_blob = blob(
          iv_repository_id = iv_repository_id
          iv_algorithm     = ls_head_key-algorithm
          iv_oid           = ls_change-new_oid ).
      ENDIF.
      IF ls_old_blob-binary = abap_true OR ls_new_blob-binary = abap_true.
        ls_file-binary = abap_true.
        ls_file-patch = |Binary files differ|.
      ELSEIF ls_old_blob-large = abap_true OR ls_new_blob-large = abap_true.
        ls_file-truncated = abap_true.
        ls_file-patch = |File is too large to render as a diff|.
      ELSE.
        IF ls_change-old_oid IS INITIAL.
          lv_old_label = '/dev/null'.
        ELSE.
          lv_old_label = |a/{ ls_change-path }|.
        ENDIF.
        IF ls_change-new_oid IS INITIAL.
          lv_new_label = '/dev/null'.
        ELSE.
          lv_new_label = |b/{ ls_change-path }|.
        ENDIF.
        ls_diff = zcl_hithub_unified_diff=>build(
          iv_old_label = lv_old_label
          iv_new_label = lv_new_label
          iv_old       = ls_old_blob-text
          iv_new       = ls_new_blob-text ).
        ls_file-additions = ls_diff-additions.
        ls_file-deletions = ls_diff-deletions.
        ls_file-patch = ls_diff-patch.
        rs_comparison-additions = rs_comparison-additions + ls_diff-additions.
        rs_comparison-deletions = rs_comparison-deletions + ls_diff-deletions.
      ENDIF.
      APPEND ls_file TO rs_comparison-files.
    ENDLOOP.
  ENDMETHOD.

  METHOD resolve.
    DATA lv_name TYPE string.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_tag TYPE zcl_hithub_tag_codec=>ty_tag.
    DATA lv_peel TYPE i.

    CLEAR rs_key.
    lv_name = iv_reference.
    IF lv_name CP 'refs/*'.
      ls_reference = mo_metadata->read_reference(
        iv_repository_id = iv_repository_id iv_name = lv_name ).
    ELSE.
      ls_reference = mo_metadata->read_reference(
        iv_repository_id = iv_repository_id
        iv_name          = |refs/heads/{ lv_name }| ).
      IF ls_reference-oid IS INITIAL.
        ls_reference = mo_metadata->read_reference(
          iv_repository_id = iv_repository_id
          iv_name          = |refs/tags/{ lv_name }| ).
      ENDIF.
    ENDIF.
    IF ls_reference-oid IS INITIAL.
      IF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha1' iv_oid = lv_name ) = abap_true.
        ls_reference-algorithm = 'sha1'.
        ls_reference-oid = lv_name.
      ELSEIF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha256' iv_oid = lv_name ) = abap_true.
        ls_reference-algorithm = 'sha256'.
        ls_reference-oid = lv_name.
      ELSE.
        RETURN.
      ENDIF.
    ENDIF.

    rs_key-repository_id = iv_repository_id.
    rs_key-algorithm = ls_reference-algorithm.
    rs_key-oid = ls_reference-oid.
    WHILE lv_peel < 5.
      ls_object = mo_objects->read( rs_key ).
      IF ls_object-type <> 'tag'.
        EXIT.
      ENDIF.
      ls_tag = zcl_hithub_tag_codec=>decode( ls_object-payload ).
      IF ls_tag-object IS INITIAL.
        EXIT.
      ENDIF.
      rs_key-oid = ls_tag-object.
      lv_peel = lv_peel + 1.
    ENDWHILE.
    IF ls_object-type <> 'commit'.
      CLEAR rs_key.
    ENDIF.
  ENDMETHOD.

  METHOD tree_of.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.

    CLEAR rv_tree.
    IF is_commit-oid IS INITIAL.
      RETURN.
    ENDIF.
    ls_object = mo_objects->read( is_commit ).
    IF ls_object-type <> 'commit'.
      RETURN.
    ENDIF.
    ls_commit = zcl_hithub_commit_codec=>decode( ls_object-payload ).
    rv_tree = ls_commit-tree.
  ENDMETHOD.

  METHOD flatten.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_file TYPE zcl_hithub_changed_files=>ty_file.
    DATA lv_oid TYPE string.
    DATA lv_path TYPE string.

    IF iv_tree_oid IS INITIAL OR iv_depth >= c_tree_depth.
      RETURN.
    ENDIF.
    ls_key-repository_id = iv_repository_id.
    ls_key-algorithm = iv_algorithm.
    ls_key-oid = iv_tree_oid.
    ls_object = mo_objects->read( ls_key ).
    IF ls_object-type <> 'tree'.
      RETURN.
    ENDIF.
    lt_entries = zcl_hithub_tree_codec=>decode(
      iv_payload    = ls_object-payload
      iv_oid_length = oid_length( iv_algorithm ) ).
    LOOP AT lt_entries INTO ls_entry.
      lv_oid = ls_entry-oid.
      IF iv_prefix IS INITIAL.
        lv_path = ls_entry-name.
      ELSE.
        lv_path = |{ iv_prefix }/{ ls_entry-name }|.
      ENDIF.
      IF ls_entry-mode = '040000'.
        flatten(
          EXPORTING
            iv_repository_id = iv_repository_id
            iv_algorithm     = iv_algorithm
            iv_tree_oid      = lv_oid
            iv_prefix        = lv_path
            iv_depth         = iv_depth + 1
          CHANGING
            ct_files         = ct_files ).
        CONTINUE.
      ENDIF.
      CLEAR ls_file.
      ls_file-path = lv_path.
      ls_file-oid = lv_oid.
      ls_file-mode = ls_entry-mode.
      APPEND ls_file TO ct_files.
    ENDLOOP.
  ENDMETHOD.

  METHOD collect_history.
    DATA lt_pending TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_decoded TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_commit TYPE zcl_hithub_merge_base=>ty_commit.
    DATA lv_oid TYPE string.
    DATA lv_parent TYPE string.
    DATA lv_visited TYPE i.

    IF iv_oid IS INITIAL.
      RETURN.
    ENDIF.
    APPEND iv_oid TO lt_pending.
    WHILE lines( lt_pending ) > 0 AND lv_visited < c_history_limit.
      READ TABLE lt_pending INDEX 1 INTO lv_oid.
      DELETE lt_pending INDEX 1.
      IF line_exists( ct_commits[ oid = lv_oid ] ).
        CONTINUE.
      ENDIF.
      lv_visited = lv_visited + 1.
      CLEAR ls_key.
      ls_key-repository_id = iv_repository_id.
      ls_key-algorithm = iv_algorithm.
      ls_key-oid = lv_oid.
      ls_object = mo_objects->read( ls_key ).
      IF ls_object-type <> 'commit'.
        CONTINUE.
      ENDIF.
      ls_decoded = zcl_hithub_commit_codec=>decode( ls_object-payload ).
      CLEAR ls_commit.
      ls_commit-oid = lv_oid.
      READ TABLE ls_decoded-parents INDEX 1 INTO ls_commit-parent.
      READ TABLE ls_decoded-parents INDEX 2 INTO ls_commit-parent2.
      APPEND ls_commit TO ct_commits.
      LOOP AT ls_decoded-parents INTO lv_parent.
        IF lv_parent IS NOT INITIAL
            AND NOT line_exists( ct_commits[ oid = lv_parent ] ).
          APPEND lv_parent TO lt_pending.
        ENDIF.
      ENDLOOP.
    ENDWHILE.
  ENDMETHOD.

  METHOD blob.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    CLEAR rs_blob.
    IF iv_oid IS INITIAL.
      RETURN.
    ENDIF.
    ls_key-repository_id = iv_repository_id.
    ls_key-algorithm = iv_algorithm.
    ls_key-oid = iv_oid.
    ls_object = mo_objects->read( ls_key ).
    IF ls_object-type <> 'blob'.
      RETURN.
    ENDIF.
    rs_blob-found = abap_true.
    IF xstrlen( ls_object-payload ) > c_max_blob_size.
      rs_blob-large = abap_true.
      RETURN.
    ENDIF.
    IF is_binary( ls_object-payload ) = abap_true.
      rs_blob-binary = abap_true.
      RETURN.
    ENDIF.
    IF ls_object-payload IS INITIAL.
      RETURN.
    ENDIF.
    rs_blob-text = cl_abap_codepage=>convert_from( source = ls_object-payload ).
  ENDMETHOD.

  METHOD is_binary.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_byte TYPE x LENGTH 1.

    CLEAR rv_binary.
    lv_length = xstrlen( iv_payload ).
    IF lv_length > c_binary_probe.
      lv_length = c_binary_probe.
    ENDIF.
    WHILE lv_offset < lv_length.
      lv_byte = iv_payload+lv_offset(1).
      IF lv_byte IS INITIAL.
        rv_binary = abap_true.
        RETURN.
      ENDIF.
      lv_offset = lv_offset + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD oid_length.
    IF iv_algorithm = 'sha256'.
      rv_length = 32.
    ELSE.
      rv_length = 20.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
