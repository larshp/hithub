CLASS zcl_hithub_issues DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_open TYPE string VALUE 'open'.
    CONSTANTS c_closed TYPE string VALUE 'closed'.
    TYPES:
      BEGIN OF ty_issue,
        repository_id TYPE string,
        id            TYPE string,
        title         TYPE string,
        body          TYPE string,
        state         TYPE string,
        actor         TYPE string,
        created_at    TYPE string,
        updated_at    TYPE string,
        version       TYPE int8,
      END OF ty_issue,
      ty_issues TYPE STANDARD TABLE OF ty_issue WITH DEFAULT KEY,
      BEGIN OF ty_result,
        success TYPE abap_bool,
        reason  TYPE string,
        issue   TYPE ty_issue,
      END OF ty_result.

    CLASS-METHODS create
      IMPORTING
        is_issue TYPE ty_issue
      RETURNING
        VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS read
      IMPORTING
        iv_repository_id TYPE string
        iv_id            TYPE string
      RETURNING
        VALUE(rs_issue) TYPE ty_issue.

    CLASS-METHODS list
      IMPORTING
        iv_repository_id TYPE string
      RETURNING
        VALUE(rt_issues) TYPE ty_issues.

    CLASS-METHODS update
      IMPORTING
        iv_repository_id   TYPE string
        iv_id              TYPE string
        iv_title           TYPE string
        iv_body            TYPE string
        iv_expected_version TYPE int8
      RETURNING
        VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS transition
      IMPORTING
        iv_repository_id    TYPE string
        iv_id               TYPE string
        iv_state            TYPE string
        iv_expected_version TYPE int8
      RETURNING
        VALUE(rs_result) TYPE ty_result.
ENDCLASS.

CLASS zcl_hithub_issues IMPLEMENTATION.

  METHOD create.
    DATA ls_row TYPE zhi_issue.
    DATA ls_existing TYPE zhi_issue.
    DATA ls_issue TYPE ty_issue.

    CLEAR rs_result.
    ls_issue = is_issue.
    IF ls_issue-repository_id IS INITIAL OR ls_issue-id IS INITIAL
        OR strlen( ls_issue-id ) > 36 OR ls_issue-title IS INITIAL
        OR strlen( ls_issue-title ) > 255 OR ls_issue-actor IS INITIAL
        OR strlen( ls_issue-actor ) > 100.
      rs_result-reason = 'issue identity, title, or actor is invalid'.
      RETURN.
    ENDIF.
    IF ls_issue-state IS INITIAL.
      ls_issue-state = c_open.
    ELSEIF ls_issue-state <> c_open.
      rs_result-reason = 'new issues must be open'.
      RETURN.
    ENDIF.
    IF ls_issue-created_at IS INITIAL.
      GET TIME STAMP FIELD ls_issue-created_at.
    ENDIF.
    IF ls_issue-updated_at IS INITIAL.
      ls_issue-updated_at = ls_issue-created_at.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue INTO @ls_existing
      WHERE repository_id = @ls_issue-repository_id
        AND id = @ls_issue-id.
    IF sy-subrc = 0.
      rs_result-reason = 'issue already exists'.
      RETURN.
    ENDIF.

    ls_row-repository_id = ls_issue-repository_id.
    ls_row-id = ls_issue-id.
    ls_row-title = ls_issue-title.
    ls_row-body = ls_issue-body.
    ls_row-state = ls_issue-state.
    ls_row-actor = ls_issue-actor.
    ls_row-created_at = ls_issue-created_at.
    ls_row-updated_at = ls_issue-updated_at.
    ls_row-version = 1.
    INSERT zhi_issue FROM @ls_row.
    IF sy-subrc <> 0.
      rs_result-reason = 'issue could not be persisted'.
      RETURN.
    ENDIF.
    ls_issue-version = 1.
    rs_result-success = abap_true.
    rs_result-issue = ls_issue.
  ENDMETHOD.

  METHOD read.
    DATA ls_row TYPE zhi_issue.

    CLEAR rs_issue.
    IF iv_repository_id IS INITIAL OR iv_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue INTO @ls_row
      WHERE repository_id = @iv_repository_id
        AND id = @iv_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    rs_issue-repository_id = ls_row-repository_id.
    rs_issue-id = ls_row-id.
    rs_issue-title = ls_row-title.
    rs_issue-body = ls_row-body.
    rs_issue-state = ls_row-state.
    rs_issue-actor = ls_row-actor.
    rs_issue-created_at = ls_row-created_at.
    rs_issue-updated_at = ls_row-updated_at.
    rs_issue-version = ls_row-version.
  ENDMETHOD.

  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_issue.
    DATA ls_row TYPE zhi_issue.
    DATA ls_issue TYPE ty_issue.

    CLEAR rt_issues.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_issue INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_issue.
      ls_issue-repository_id = ls_row-repository_id.
      ls_issue-id = ls_row-id.
      ls_issue-title = ls_row-title.
      ls_issue-body = ls_row-body.
      ls_issue-state = ls_row-state.
      ls_issue-actor = ls_row-actor.
      ls_issue-created_at = ls_row-created_at.
      ls_issue-updated_at = ls_row-updated_at.
      ls_issue-version = ls_row-version.
      APPEND ls_issue TO rt_issues.
    ENDLOOP.
    SORT rt_issues BY id.
  ENDMETHOD.

  METHOD update.
    DATA ls_row TYPE zhi_issue.

    CLEAR rs_result.
    IF iv_repository_id IS INITIAL OR iv_id IS INITIAL
        OR iv_title IS INITIAL OR strlen( iv_title ) > 255
        OR iv_expected_version <= 0.
      rs_result-reason = 'issue update is invalid'.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue INTO @ls_row
      WHERE repository_id = @iv_repository_id
        AND id = @iv_id.
    IF sy-subrc <> 0.
      rs_result-reason = 'issue was not found'.
      RETURN.
    ENDIF.
    IF ls_row-version <> iv_expected_version.
      rs_result-reason = 'issue version is stale'.
      RETURN.
    ENDIF.
    ls_row-title = iv_title.
    ls_row-body = iv_body.
    ls_row-updated_at = ls_row-created_at.
    GET TIME STAMP FIELD ls_row-updated_at.
    ls_row-version = ls_row-version + 1.
    UPDATE zhi_issue FROM @ls_row.
    IF sy-subrc <> 0.
      rs_result-reason = 'issue update failed'.
      RETURN.
    ENDIF.
    rs_result-success = abap_true.
    rs_result-issue = zcl_hithub_issues=>read(
      iv_repository_id = iv_repository_id iv_id = iv_id ).
  ENDMETHOD.

  METHOD transition.
    DATA ls_row TYPE zhi_issue.

    CLEAR rs_result.
    IF iv_repository_id IS INITIAL OR iv_id IS INITIAL
        OR iv_expected_version <= 0
        OR ( iv_state <> c_open AND iv_state <> c_closed ).
      rs_result-reason = 'issue transition is invalid'.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue INTO @ls_row
      WHERE repository_id = @iv_repository_id
        AND id = @iv_id.
    IF sy-subrc <> 0.
      rs_result-reason = 'issue was not found'.
      RETURN.
    ENDIF.
    IF ls_row-version <> iv_expected_version.
      rs_result-reason = 'issue version is stale'.
      RETURN.
    ENDIF.
    IF ls_row-state = iv_state.
      rs_result-reason = 'issue is already in that state'.
      RETURN.
    ENDIF.
    ls_row-state = iv_state.
    GET TIME STAMP FIELD ls_row-updated_at.
    ls_row-version = ls_row-version + 1.
    UPDATE zhi_issue FROM @ls_row.
    IF sy-subrc <> 0.
      rs_result-reason = 'issue transition failed'.
      RETURN.
    ENDIF.
    rs_result-success = abap_true.
    rs_result-issue = zcl_hithub_issues=>read(
      iv_repository_id = iv_repository_id iv_id = iv_id ).
  ENDMETHOD.

ENDCLASS.
