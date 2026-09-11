CLASS ltcl_timeline DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS lists_issue_and_pr_events FOR TESTING RAISING cx_static_check.
    METHODS rejects_other_subject_types FOR TESTING RAISING cx_static_check.
    METHODS lists_repository_activity FOR TESTING RAISING cx_static_check.
    METHODS orders_equal_timestamps FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_timeline IMPLEMENTATION.

  METHOD lists_issue_and_pr_events.
    DATA(lo_sink) = NEW zcl_hithub_local_event_sink( ).
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.
    DATA lt_entries TYPE zcl_hithub_timeline=>ty_entries.

    ls_event-action = 'issue.create'.
    ls_event-subject_type = zcl_hithub_timeline=>c_issue.
    ls_event-subject_id = 'timeline-issue-1'.
    ls_event-occurred_at = '20260828120000.0000000'.
    ls_event-details = 'title=timeline'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).

    CLEAR ls_event.
    ls_event-actor = 'runtime-actor'.
    ls_event-action = 'issue.close'.
    ls_event-subject_type = zcl_hithub_timeline=>c_issue.
    ls_event-subject_id = 'timeline-issue-1'.
    ls_event-correlation_id = 'timeline-correlation'.
    ls_event-occurred_at = '20260828130000.0000000'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).

    CLEAR ls_event.
    ls_event-action = 'merge'.
    ls_event-subject_type = zcl_hithub_timeline=>c_pull_request.
    ls_event-subject_id = 'timeline-pr-1'.
    ls_event-occurred_at = '20260828140000.0000000'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).

    lt_entries = zcl_hithub_timeline=>list(
      iv_subject_type = zcl_hithub_timeline=>c_issue
      iv_subject_id   = 'timeline-issue-1' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_entries ) exp = 2 ).
    READ TABLE lt_entries INDEX 1 INTO DATA(ls_first).
    cl_abap_unit_assert=>assert_equals(
      act = ls_first-action
      exp = 'issue.create' ).
    cl_abap_unit_assert=>assert_initial( act = ls_first-actor ).
    READ TABLE lt_entries INDEX 2 INTO DATA(ls_second).
    cl_abap_unit_assert=>assert_equals(
      act = ls_second-action
      exp = 'issue.close' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_second-actor
      exp = 'runtime-actor' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_second-correlation_id
      exp = 'timeline-correlation' ).

    lt_entries = zcl_hithub_timeline=>list(
      iv_subject_type = zcl_hithub_timeline=>c_pull_request
      iv_subject_id   = 'timeline-pr-1' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_entries ) exp = 1 ).
    READ TABLE lt_entries INDEX 1 INTO DATA(ls_pr_entry).
    cl_abap_unit_assert=>assert_equals(
      act = ls_pr_entry-action
      exp = 'merge' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_pr_entry-subject_type
      exp = zcl_hithub_timeline=>c_pull_request ).
  ENDMETHOD.

  METHOD rejects_other_subject_types.
    DATA(lt_entries) = zcl_hithub_timeline=>list(
      iv_subject_type = 'repository'
      iv_subject_id   = 'timeline-repository-1' ).
    cl_abap_unit_assert=>assert_initial( act = lt_entries ).
  ENDMETHOD.

  METHOD lists_repository_activity.
    DATA(lo_sink) = NEW zcl_hithub_local_event_sink( ).
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.

    ls_event-action = 'issue.create'.
    ls_event-subject_type = zcl_hithub_timeline=>c_issue.
    ls_event-subject_id = 'activity-issue-1'.
    ls_event-occurred_at = '20260828150000.0000000'.
    ls_event-details = 'repository=activity-repository'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).
    CLEAR ls_event.
    ls_event-action = 'repository.create'.
    ls_event-subject_type = 'repository'.
    ls_event-subject_id = 'activity-repository'.
    ls_event-occurred_at = '20260828140000.0000000'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).
    CLEAR ls_event.
    ls_event-action = 'issue.create'.
    ls_event-subject_type = zcl_hithub_timeline=>c_issue.
    ls_event-subject_id = 'other-issue-1'.
    ls_event-occurred_at = '20260828160000.0000000'.
    ls_event-details = 'repository=other-repository'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).

    DATA(lt_entries) = zcl_hithub_timeline=>list_repository(
      iv_repository_id = 'activity-repository' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_entries ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_entries[ 1 ]-action
      exp = 'repository.create' ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_entries[ 2 ]-subject_id
      exp = 'activity-issue-1' ).
  ENDMETHOD.

  METHOD orders_equal_timestamps.
    DATA(lo_sink) = NEW zcl_hithub_local_event_sink( ).
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.

    ls_event-action = 'first'.
    ls_event-subject_type = zcl_hithub_timeline=>c_issue.
    ls_event-subject_id = 'same-time-issue'.
    ls_event-occurred_at = '20260828170000.0000000'.
    ls_event-details = 'repository=same-time-repository'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).
    CLEAR ls_event.
    ls_event-action = 'second'.
    ls_event-subject_type = zcl_hithub_timeline=>c_issue.
    ls_event-subject_id = 'same-time-issue'.
    ls_event-occurred_at = '20260828170000.0000000'.
    ls_event-details = 'repository=same-time-repository'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).

    DATA(lt_entries) = zcl_hithub_timeline=>list_repository(
      iv_repository_id = 'same-time-repository' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_entries ) exp = 2 ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lt_entries[ 1 ]-event_id < lt_entries[ 2 ]-event_id ) ).
  ENDMETHOD.

ENDCLASS.
