CLASS zcl_hithub_commit_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        oid         TYPE string,
        algorithm   TYPE string,
        tree        TYPE string,
        parents     TYPE zcl_hithub_commit_codec=>ty_parents,
        author      TYPE string,
        committer   TYPE string,
        message     TYPE string,
        authored_at TYPE string,
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
        iv_limit          TYPE i DEFAULT 100
      RETURNING
        VALUE(rt_entries) TYPE ty_entries
      RAISING
        cx_static_check.

    METHODS read
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        iv_oid           TYPE string
      RETURNING
        VALUE(rs_entry)  TYPE ty_entry
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_objects TYPE REF TO zif_hithub_object_store.

ENDCLASS.

CLASS zcl_hithub_commit_service IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_objects = io_objects.
  ENDMETHOD.

  METHOD read.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_identity TYPE zcl_hithub_commit_identity=>ty_identity.
    DATA lv_parent TYPE string.

    CLEAR rs_entry.
    IF mo_objects IS INITIAL OR iv_repository_id IS INITIAL
        OR iv_algorithm IS INITIAL OR iv_oid IS INITIAL.
      RETURN.
    ENDIF.
    ls_key-repository_id = iv_repository_id.
    ls_key-algorithm = iv_algorithm.
    ls_key-oid = iv_oid.
    ls_object = mo_objects->read( ls_key ).
    IF ls_object-type <> 'commit'.
      RETURN.
    ENDIF.
    ls_commit = zcl_hithub_commit_codec=>decode( ls_object-payload ).
    rs_entry-oid = iv_oid.
    rs_entry-algorithm = iv_algorithm.
    rs_entry-tree = ls_commit-tree.
    LOOP AT ls_commit-parents INTO lv_parent.
      IF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = iv_algorithm iv_oid = lv_parent ) = abap_true.
        APPEND lv_parent TO rs_entry-parents.
      ENDIF.
    ENDLOOP.
    rs_entry-author = ls_commit-author.
    rs_entry-committer = ls_commit-committer.
    rs_entry-message = ls_commit-message.
    ls_identity = zcl_hithub_commit_identity=>parse( ls_commit-author ).
    IF ls_identity-unix_seconds <> 0.
      rs_entry-authored_at = |{ ls_identity-unix_seconds }|.
    ENDIF.
  ENDMETHOD.

  METHOD list.
    TYPES ty_seen TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA lv_ref TYPE string.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_pending TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_seen TYPE ty_seen.
    DATA lv_oid TYPE string.
    DATA lv_parent TYPE string.
    DATA ls_entry TYPE ty_entry.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_tag TYPE zcl_hithub_tag_codec=>ty_tag.

    CLEAR rt_entries.
    IF mo_metadata IS INITIAL OR mo_objects IS INITIAL
        OR iv_repository_id IS INITIAL OR iv_ref IS INITIAL OR iv_limit <= 0.
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

    ls_key-repository_id = iv_repository_id.
    ls_key-algorithm = ls_reference-algorithm.
    ls_key-oid = ls_reference-oid.
    ls_object = mo_objects->read( ls_key ).
    IF ls_object-type = 'tag'.
      ls_tag = zcl_hithub_tag_codec=>decode( ls_object-payload ).
      IF ls_tag-type <> 'commit' OR ls_tag-object IS INITIAL.
        RETURN.
      ENDIF.
      ls_reference-oid = ls_tag-object.
    ENDIF.

    APPEND ls_reference-oid TO lt_pending.
    WHILE lines( lt_pending ) > 0 AND lines( rt_entries ) < iv_limit.
      READ TABLE lt_pending INTO lv_oid INDEX 1.
      DELETE lt_pending INDEX 1.
      IF line_exists( lt_seen[ table_line = lv_oid ] ).
        CONTINUE.
      ENDIF.
      INSERT lv_oid INTO TABLE lt_seen.
      ls_entry = read(
        iv_repository_id = iv_repository_id
        iv_algorithm     = ls_reference-algorithm
        iv_oid           = lv_oid ).
      IF ls_entry-oid IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND ls_entry TO rt_entries.
      LOOP AT ls_entry-parents INTO lv_parent.
        IF NOT line_exists( lt_seen[ table_line = lv_parent ] ).
          APPEND lv_parent TO lt_pending.
        ENDIF.
      ENDLOOP.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
