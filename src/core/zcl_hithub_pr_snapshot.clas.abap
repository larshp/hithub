CLASS zcl_hithub_pr_snapshot DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
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
      END OF ty_snapshot.
    TYPES ty_snapshots TYPE STANDARD TABLE OF ty_snapshot WITH DEFAULT KEY.

    CLASS-METHODS open
      IMPORTING
        is_snapshot TYPE ty_snapshot
      RETURNING
        VALUE(rv_saved) TYPE abap_bool.

    CLASS-METHODS read
      IMPORTING
        iv_repository_id TYPE string
        iv_id            TYPE string
      RETURNING
        VALUE(rs_snapshot) TYPE ty_snapshot.
ENDCLASS.

CLASS zcl_hithub_pr_snapshot IMPLEMENTATION.

  METHOD open.
    DATA ls_row TYPE zhi_pull_request.
    DATA ls_existing TYPE zhi_pull_request.

    CLEAR rv_saved.
    IF is_snapshot-repository_id IS INITIAL
        OR is_snapshot-id IS INITIAL
        OR is_snapshot-source_ref IS INITIAL
        OR is_snapshot-target_ref IS INITIAL
        OR is_snapshot-base_oid IS INITIAL
        OR is_snapshot-head_oid IS INITIAL
        OR zcl_hithub_pull_request_state=>is_valid( is_snapshot-state ) = abap_false.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_pull_request INTO @ls_existing
      WHERE repository_id = @is_snapshot-repository_id
        AND id = @is_snapshot-id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = is_snapshot-repository_id.
    ls_row-id = is_snapshot-id.
    ls_row-state = is_snapshot-state.
    ls_row-source_ref = is_snapshot-source_ref.
    ls_row-target_ref = is_snapshot-target_ref.
    ls_row-base_oid = is_snapshot-base_oid.
    ls_row-head_oid = is_snapshot-head_oid.
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
    rs_snapshot-version = ls_row-version.
  ENDMETHOD.

ENDCLASS.
