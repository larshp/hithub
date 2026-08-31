CLASS zcl_hithub_contents_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        name           TYPE string,
        type           TYPE string,
        mode           TYPE string,
        algorithm      TYPE string,
        oid            TYPE string,
        size           TYPE int8,
        last_commit    TYPE string,
        last_commit_at TYPE string,
      END OF ty_entry,
      ty_entries TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_objects  TYPE REF TO zif_hithub_object_store.

    METHODS list
      IMPORTING
        iv_repository_id  TYPE string
        iv_ref            TYPE string
        iv_path           TYPE string OPTIONAL
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
        VALUE(rs_key)    TYPE zif_hithub_object_store=>ty_object_key
      RAISING
        cx_static_check.

    METHODS commit_for_ref
      IMPORTING
        iv_repository_id TYPE string
        iv_ref           TYPE string
      RETURNING
        VALUE(rs_key)    TYPE zif_hithub_object_store=>ty_object_key
      RAISING
        cx_static_check.

    METHODS find_path
      IMPORTING
        iv_repository_id TYPE string
        iv_ref           TYPE string
        iv_path          TYPE string
      RETURNING
        VALUE(rs_entry)  TYPE ty_entry
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_contents_service IMPLEMENTATION.

  METHOD commit_for_ref.
    DATA lv_ref TYPE string.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_tag TYPE zcl_hithub_tag_codec=>ty_tag.
    DATA lv_peel TYPE i.

    CLEAR rs_key.
    IF mo_metadata IS INITIAL OR iv_repository_id IS INITIAL OR iv_ref IS INITIAL.
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
      " Browsing history means asking for a plain commit id as well as a ref.
      IF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha1' iv_oid = iv_ref ) = abap_true.
        ls_reference-algorithm = 'sha1'.
      ELSEIF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha256' iv_oid = iv_ref ) = abap_true.
        ls_reference-algorithm = 'sha256'.
      ELSE.
        RETURN.
      ENDIF.
      ls_reference-oid = iv_ref.
    ENDIF.
    rs_key-repository_id = iv_repository_id.
    rs_key-algorithm = ls_reference-algorithm.
    rs_key-oid = ls_reference-oid.
    IF mo_objects IS INITIAL.
      RETURN.
    ENDIF.
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

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
  ENDMETHOD.

  METHOD tree_for_ref.
    DATA ls_commit_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_commit_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.

    CLEAR rs_key.
    IF mo_objects IS INITIAL OR iv_repository_id IS INITIAL OR iv_ref IS INITIAL.
      RETURN.
    ENDIF.
    ls_commit_key = commit_for_ref(
      iv_repository_id = iv_repository_id iv_ref = iv_ref ).
    IF ls_commit_key-oid IS INITIAL.
      RETURN.
    ENDIF.
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
    DATA ls_commit_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_commit_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_identity TYPE zcl_hithub_commit_identity=>ty_identity.
    DATA lv_commit_at TYPE string.

    CLEAR rt_entries.
    ls_directory = find_path(
      iv_repository_id = iv_repository_id iv_ref = iv_ref iv_path = iv_path ).
    IF ls_directory-type <> 'tree'.
      RETURN.
    ENDIF.
    ls_commit_key = commit_for_ref(
      iv_repository_id = iv_repository_id iv_ref = iv_ref ).
    IF ls_commit_key-oid IS NOT INITIAL.
      ls_commit_object = mo_objects->read( ls_commit_key ).
      IF ls_commit_object-type = 'commit'.
        ls_commit = zcl_hithub_commit_codec=>decode(
          ls_commit_object-payload ).
        ls_identity = zcl_hithub_commit_identity=>parse( ls_commit-committer ).
        IF ls_identity-unix_seconds <> 0.
          lv_commit_at = |{ ls_identity-unix_seconds }|.
        ELSEIF ls_commit_object-created_at IS NOT INITIAL.
          lv_commit_at = |{ ls_commit_object-created_at }|.
        ENDIF.
      ENDIF.
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
      ls_result-last_commit = ls_commit-message.
      ls_result-last_commit_at = lv_commit_at.
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
