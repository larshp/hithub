CLASS zcl_hithub_contents_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        name      TYPE string,
        type      TYPE string,
        mode      TYPE string,
        algorithm TYPE string,
        oid       TYPE string,
        size      TYPE int8,
      END OF ty_entry,
      ty_entries TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_objects TYPE REF TO zif_hithub_object_store.

    METHODS list
      IMPORTING
        iv_repository_id TYPE string
        iv_ref           TYPE string
        iv_path          TYPE string OPTIONAL
      RETURNING
        VALUE(rt_entries) TYPE ty_entries
      RAISING
        cx_static_check.

    METHODS read
      IMPORTING
        iv_repository_id TYPE string
        iv_ref           TYPE string
        iv_path          TYPE string
      RETURNING
        VALUE(rs_object) TYPE zif_hithub_object_store=>ty_object
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_objects TYPE REF TO zif_hithub_object_store.

    METHODS tree_for_ref
      IMPORTING
        iv_repository_id TYPE string
        iv_ref           TYPE string
      RETURNING
        VALUE(rs_key) TYPE zif_hithub_object_store=>ty_object_key
      RAISING
        cx_static_check.

    METHODS find_path
      IMPORTING
        iv_repository_id TYPE string
        iv_ref           TYPE string
        iv_path          TYPE string
      RETURNING
        VALUE(rs_entry) TYPE ty_entry
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_contents_service IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
  ENDMETHOD.

  METHOD tree_for_ref.
    DATA lv_ref TYPE string.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_commit_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_commit_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.

    CLEAR rs_key.
    IF mo_metadata IS INITIAL OR mo_objects IS INITIAL
        OR iv_repository_id IS INITIAL OR iv_ref IS INITIAL.
      RETURN.
    ENDIF.
    lv_ref = iv_ref.
    IF lv_ref NP 'refs/*'.
      lv_ref = |refs/heads/{ lv_ref }|.
    ENDIF.
    ls_reference = mo_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = lv_ref ).
    IF ls_reference-oid IS INITIAL AND iv_ref NP 'refs/*'.
      lv_ref = |refs/tags/{ iv_ref }|.
      ls_reference = mo_metadata->read_reference(
        iv_repository_id = iv_repository_id iv_name = lv_ref ).
    ENDIF.
    IF ls_reference-oid IS INITIAL.
      RETURN.
    ENDIF.
    ls_commit_key-repository_id = iv_repository_id.
    ls_commit_key-algorithm = ls_reference-algorithm.
    ls_commit_key-oid = ls_reference-oid.
    ls_commit_object = mo_objects->read( ls_commit_key ).
    IF ls_commit_object-type <> 'commit'.
      RETURN.
    ENDIF.
    ls_commit = zcl_hithub_commit_codec=>decode(
      ls_commit_object-payload ).
    IF ls_commit-tree IS INITIAL.
      RETURN.
    ENDIF.
    rs_key = ls_commit_key.
    rs_key-oid = ls_commit-tree.
  ENDMETHOD.

  METHOD find_path.
    DATA ls_tree_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_tree_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_parts TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_part TYPE string.
    DATA lv_index TYPE i.
    DATA lv_last TYPE i.
    DATA lt_tree_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_tree_entry TYPE zcl_hithub_tree_codec=>ty_entry.

    CLEAR rs_entry.
    ls_tree_key = tree_for_ref(
      iv_repository_id = iv_repository_id iv_ref = iv_ref ).
    IF ls_tree_key-oid IS INITIAL.
      RETURN.
    ENDIF.
    IF iv_path IS INITIAL.
      rs_entry-type = 'tree'.
      rs_entry-mode = '040000'.
      rs_entry-algorithm = ls_tree_key-algorithm.
      rs_entry-oid = ls_tree_key-oid.
      RETURN.
    ENDIF.

    SPLIT iv_path AT '/' INTO TABLE lt_parts.
    DELETE lt_parts WHERE table_line IS INITIAL.
    IF lines( lt_parts ) = 0.
      rs_entry-type = 'tree'.
      rs_entry-mode = '040000'.
      rs_entry-algorithm = ls_tree_key-algorithm.
      rs_entry-oid = ls_tree_key-oid.
      RETURN.
    ENDIF.
    lv_last = lines( lt_parts ).
    lv_index = 1.
    LOOP AT lt_parts INTO lv_part.
      ls_tree_object = mo_objects->read( ls_tree_key ).
      IF ls_tree_object-type <> 'tree'.
        CLEAR rs_entry.
        RETURN.
      ENDIF.
      lt_tree_entries = zcl_hithub_tree_codec=>decode(
        ls_tree_object-payload ).
      READ TABLE lt_tree_entries INTO ls_tree_entry
        WITH KEY name = lv_part.
      IF sy-subrc <> 0.
        CLEAR rs_entry.
        RETURN.
      ENDIF.
      CLEAR rs_entry.
      rs_entry-name = ls_tree_entry-name.
      rs_entry-mode = ls_tree_entry-mode.
      rs_entry-algorithm = ls_tree_key-algorithm.
      rs_entry-oid = ls_tree_entry-oid.
      IF ls_tree_entry-mode = '040000'.
        rs_entry-type = 'tree'.
      ELSE.
        rs_entry-type = 'blob'.
      ENDIF.
      IF lv_index = lv_last.
        RETURN.
      ENDIF.
      IF rs_entry-type <> 'tree'.
        CLEAR rs_entry.
        RETURN.
      ENDIF.
      ls_tree_key-oid = rs_entry-oid.
      lv_index = lv_index + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD list.
    DATA ls_directory TYPE ty_entry.
    DATA ls_tree_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_tree_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_tree_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_tree_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_object_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_result TYPE ty_entry.

    CLEAR rt_entries.
    ls_directory = find_path(
      iv_repository_id = iv_repository_id iv_ref = iv_ref iv_path = iv_path ).
    IF ls_directory-type <> 'tree'.
      RETURN.
    ENDIF.
    ls_tree_key-repository_id = iv_repository_id.
    ls_tree_key-algorithm = ls_directory-algorithm.
    ls_tree_key-oid = ls_directory-oid.
    ls_tree_object = mo_objects->read( ls_tree_key ).
    IF ls_tree_object-type <> 'tree'.
      RETURN.
    ENDIF.
    lt_tree_entries = zcl_hithub_tree_codec=>decode(
      ls_tree_object-payload ).
    LOOP AT lt_tree_entries INTO ls_tree_entry.
      CLEAR ls_result.
      ls_result-name = ls_tree_entry-name.
      ls_result-mode = ls_tree_entry-mode.
      ls_result-algorithm = ls_directory-algorithm.
      ls_result-oid = ls_tree_entry-oid.
      IF ls_tree_entry-mode = '040000'.
        ls_result-type = 'tree'.
      ELSE.
        ls_result-type = 'blob'.
        CLEAR ls_object_key.
        ls_object_key-repository_id = iv_repository_id.
        ls_object_key-algorithm = ls_directory-algorithm.
        ls_object_key-oid = ls_result-oid.
        ls_object = mo_objects->read( ls_object_key ).
        ls_result-size = ls_object-size.
      ENDIF.
      APPEND ls_result TO rt_entries.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    DATA ls_entry TYPE ty_entry.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.

    CLEAR rs_object.
    ls_entry = find_path(
      iv_repository_id = iv_repository_id iv_ref = iv_ref iv_path = iv_path ).
    IF ls_entry-type <> 'blob'.
      RETURN.
    ENDIF.
    ls_key-repository_id = iv_repository_id.
    ls_key-algorithm = ls_entry-algorithm.
    ls_key-oid = ls_entry-oid.
    rs_object = mo_objects->read( ls_key ).
  ENDMETHOD.

ENDCLASS.
