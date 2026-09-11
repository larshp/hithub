CLASS zcl_hithub_pr_snapshot DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_title_length TYPE i VALUE 255.
    CONSTANTS c_actor_length TYPE i VALUE 100.
    TYPES:
      BEGIN OF ty_snapshot,
        repository_id TYPE string,
        id            TYPE string,
        state         TYPE string,
        source_ref    TYPE string,
        target_ref    TYPE string,
        base_oid      TYPE string,
        head_oid      TYPE string,
        version       TYPE int8,
        title         TYPE string,
        body          TYPE string,
        actor         TYPE string,
        created_at    TYPE string,
        updated_at    TYPE string,
      END OF ty_snapshot.
    TYPES ty_snapshots TYPE STANDARD TABLE OF ty_snapshot WITH EMPTY KEY.

    CLASS-METHODS is_valid
      IMPORTING
        is_snapshot     TYPE ty_snapshot
        iv_require_id   TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    " Fills the fields a client may omit: a title derived from the two
    " references, and the creation and update timestamps. Idempotent, so the
    " caller and open( ) can both run it without moving the timestamps.
    CLASS-METHODS normalize
      IMPORTING
        is_snapshot        TYPE ty_snapshot
      RETURNING
        VALUE(rs_snapshot) TYPE ty_snapshot.

    CLASS-METHODS open
      IMPORTING
        is_snapshot     TYPE ty_snapshot
      RETURNING
        VALUE(rv_saved) TYPE abap_bool.

    CLASS-METHODS read
      IMPORTING
        iv_repository_id   TYPE string
        iv_id              TYPE string
      RETURNING
        VALUE(rs_snapshot) TYPE ty_snapshot.

  PRIVATE SECTION.
    CLASS-METHODS short_ref
      IMPORTING
        iv_ref         TYPE string
      RETURNING
        VALUE(rv_name) TYPE string.
ENDCLASS.

CLASS zcl_hithub_pr_snapshot IMPLEMENTATION.

  METHOD is_valid.
    rv_valid = xsdbool(
      is_snapshot-repository_id IS NOT INITIAL
      AND ( iv_require_id = abap_false OR is_snapshot-id IS NOT INITIAL )
      AND is_snapshot-source_ref IS NOT INITIAL
      AND is_snapshot-target_ref IS NOT INITIAL
      AND is_snapshot-base_oid IS NOT INITIAL
      AND is_snapshot-head_oid IS NOT INITIAL
      AND strlen( is_snapshot-title ) <= c_title_length
      AND strlen( is_snapshot-actor ) <= c_actor_length
      AND zcl_hithub_pull_request_state=>is_valid( is_snapshot-state ) = abap_true ).
  ENDMETHOD.

  METHOD normalize.
    DATA lv_now TYPE timestamp.

    rs_snapshot = is_snapshot.
    IF rs_snapshot-title IS INITIAL.
      rs_snapshot-title = |{ short_ref( rs_snapshot-source_ref ) } into { short_ref( rs_snapshot-target_ref ) }|.
      " Two 160-character references outrun the title column on their own.
      IF strlen( rs_snapshot-title ) > c_title_length.
        rs_snapshot-title = substring(
          val = rs_snapshot-title off = 0 len = c_title_length ).
      ENDIF.
    ENDIF.
    IF rs_snapshot-created_at IS INITIAL.
      GET TIME STAMP FIELD lv_now.
      rs_snapshot-created_at = |{ lv_now }|.
    ENDIF.
    IF rs_snapshot-updated_at IS INITIAL.
      rs_snapshot-updated_at = rs_snapshot-created_at.
    ENDIF.
  ENDMETHOD.

  METHOD open.
    DATA ls_row TYPE zhi_pull_request.
    DATA ls_existing TYPE zhi_pull_request.
    DATA ls_snapshot TYPE ty_snapshot.

    CLEAR rv_saved.
    IF is_valid( is_snapshot ) = abap_false.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_pull_request INTO @ls_existing
      WHERE repository_id = @is_snapshot-repository_id
        AND id = @is_snapshot-id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_snapshot = normalize( is_snapshot ).
    ls_row-repository_id = ls_snapshot-repository_id.
    ls_row-id = ls_snapshot-id.
    ls_row-state = ls_snapshot-state.
    ls_row-source_ref = ls_snapshot-source_ref.
    ls_row-target_ref = ls_snapshot-target_ref.
    ls_row-base_oid = ls_snapshot-base_oid.
    ls_row-head_oid = ls_snapshot-head_oid.
    ls_row-title = ls_snapshot-title.
    ls_row-body = ls_snapshot-body.
    ls_row-actor = ls_snapshot-actor.
    ls_row-created_at = ls_snapshot-created_at.
    ls_row-updated_at = ls_snapshot-updated_at.
    ls_row-version = 1.
    INSERT zhi_pull_request FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD read.
    DATA ls_row TYPE zhi_pull_request.

    CLEAR rs_snapshot.
    SELECT SINGLE * FROM zhi_pull_request INTO @ls_row
      WHERE repository_id = @iv_repository_id AND id = @iv_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    rs_snapshot-repository_id = ls_row-repository_id.
    rs_snapshot-id = ls_row-id.
    rs_snapshot-state = ls_row-state.
    rs_snapshot-source_ref = ls_row-source_ref.
    rs_snapshot-target_ref = ls_row-target_ref.
    rs_snapshot-base_oid = ls_row-base_oid.
    rs_snapshot-head_oid = ls_row-head_oid.
    rs_snapshot-title = ls_row-title.
    rs_snapshot-body = ls_row-body.
    rs_snapshot-actor = ls_row-actor.
    rs_snapshot-created_at = ls_row-created_at.
    rs_snapshot-updated_at = ls_row-updated_at.
    rs_snapshot-version = ls_row-version.
  ENDMETHOD.

  METHOD short_ref.
    rv_name = iv_ref.
    IF rv_name CP 'refs/heads/*'.
      rv_name = substring( val = rv_name off = 11 ).
    ELSEIF rv_name CP 'refs/tags/*'.
      rv_name = substring( val = rv_name off = 10 ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
