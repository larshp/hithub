CLASS zcl_hithub_timeline DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_issue TYPE string VALUE 'issue'.
    CONSTANTS c_pull_request TYPE string VALUE 'pull_request'.
    TYPES:
      BEGIN OF ty_entry,
        event_id       TYPE string,
        actor          TYPE string,
        action         TYPE string,
        subject_type   TYPE string,
        subject_id     TYPE string,
        correlation_id TYPE string,
        occurred_at    TYPE string,
        details        TYPE string,
      END OF ty_entry,
      ty_entries TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    CLASS-METHODS list
      IMPORTING
        iv_subject_type TYPE string
        iv_subject_id   TYPE string
      RETURNING
        VALUE(rt_entries) TYPE ty_entries.

    CLASS-METHODS list_repository
      IMPORTING
        iv_repository_id TYPE string
      RETURNING
        VALUE(rt_entries) TYPE ty_entries.
ENDCLASS.

CLASS zcl_hithub_timeline IMPLEMENTATION.

  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_event.
    DATA ls_row TYPE zhi_event.
    DATA ls_entry TYPE ty_entry.

    CLEAR rt_entries.
    IF iv_subject_id IS INITIAL
        OR ( iv_subject_type <> c_issue
        AND iv_subject_type <> c_pull_request ).
      RETURN.
    ENDIF.

    SELECT * FROM zhi_event INTO TABLE @lt_rows
      WHERE subject_type = @iv_subject_type
        AND subject_id = @iv_subject_id.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_entry.
      ls_entry-event_id = ls_row-event_id.
      ls_entry-actor = ls_row-actor.
      ls_entry-action = ls_row-action.
      ls_entry-subject_type = ls_row-subject_type.
      ls_entry-subject_id = ls_row-subject_id.
      ls_entry-correlation_id = ls_row-correlation_id.
      ls_entry-occurred_at = ls_row-occurred_at.
      ls_entry-details = ls_row-details.
      APPEND ls_entry TO rt_entries.
    ENDLOOP.
    SORT rt_entries BY occurred_at event_id.
  ENDMETHOD.

  METHOD list_repository.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_event.
    DATA ls_row TYPE zhi_event.
    DATA ls_entry TYPE ty_entry.
    DATA lv_scope TYPE string.

    CLEAR rt_entries.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    lv_scope = |repository={ iv_repository_id }|.
    SELECT * FROM zhi_event INTO TABLE @lt_rows.
    LOOP AT lt_rows INTO ls_row.
      IF ( ls_row-subject_type = 'repository'
          AND ls_row-subject_id = iv_repository_id )
          OR ls_row-details CS lv_scope.
        CLEAR ls_entry.
        ls_entry-event_id = ls_row-event_id.
        ls_entry-actor = ls_row-actor.
        ls_entry-action = ls_row-action.
        ls_entry-subject_type = ls_row-subject_type.
        ls_entry-subject_id = ls_row-subject_id.
        ls_entry-correlation_id = ls_row-correlation_id.
        ls_entry-occurred_at = ls_row-occurred_at.
        ls_entry-details = ls_row-details.
        APPEND ls_entry TO rt_entries.
      ENDIF.
    ENDLOOP.
    SORT rt_entries BY occurred_at event_id.
  ENDMETHOD.

ENDCLASS.
