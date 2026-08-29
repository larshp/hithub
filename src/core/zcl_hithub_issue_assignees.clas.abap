CLASS zcl_hithub_issue_assignees DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_assignees TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLASS-METHODS add
      IMPORTING
        iv_repository_id TYPE string
        iv_issue_id      TYPE string
        iv_actor         TYPE string
      RETURNING
        VALUE(rv_saved)  TYPE abap_bool.

    CLASS-METHODS remove
      IMPORTING
        iv_repository_id  TYPE string
        iv_issue_id       TYPE string
        iv_actor          TYPE string
      RETURNING
        VALUE(rv_removed) TYPE abap_bool.

    CLASS-METHODS list
      IMPORTING
        iv_repository_id    TYPE string
        iv_issue_id         TYPE string
      RETURNING
        VALUE(rt_assignees) TYPE ty_assignees.
ENDCLASS.

CLASS zcl_hithub_issue_assignees IMPLEMENTATION.

  METHOD add.
    DATA ls_row TYPE zhi_issue_assignee.
    DATA ls_existing TYPE zhi_issue_assignee.

    CLEAR rv_saved.
    IF iv_repository_id IS INITIAL OR iv_issue_id IS INITIAL
        OR iv_actor IS INITIAL OR strlen( iv_actor ) > 100.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue_assignee INTO @ls_existing
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id
        AND actor = @iv_actor.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = iv_repository_id.
    ls_row-issue_id = iv_issue_id.
    ls_row-actor = iv_actor.
    INSERT zhi_issue_assignee FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD remove.
    DATA ls_existing TYPE zhi_issue_assignee.

    CLEAR rv_removed.
    IF iv_repository_id IS INITIAL OR iv_issue_id IS INITIAL
        OR iv_actor IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue_assignee INTO @ls_existing
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id
        AND actor = @iv_actor.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DELETE FROM zhi_issue_assignee
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id
        AND actor = @iv_actor.
    rv_removed = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_issue_assignee.
    DATA ls_row TYPE zhi_issue_assignee.

    CLEAR rt_assignees.
    IF iv_repository_id IS INITIAL OR iv_issue_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_issue_assignee INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id.
    LOOP AT lt_rows INTO ls_row.
      APPEND ls_row-actor TO rt_assignees.
    ENDLOOP.
    SORT rt_assignees.
  ENDMETHOD.

ENDCLASS.
