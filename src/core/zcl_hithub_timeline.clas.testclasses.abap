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
    ASSERT lines( lt_entries ) = 2.
    READ TABLE lt_entries INDEX 1 INTO DATA(ls_first).
    ASSERT ls_first-action = 'issue.create'.
    ASSERT ls_first-actor IS INITIAL.
    READ TABLE lt_entries INDEX 2 INTO DATA(ls_second).
    ASSERT ls_second-action = 'issue.close'.
    ASSERT ls_second-actor = 'runtime-actor'.
    ASSERT ls_second-correlation_id = 'timeline-correlation'.

    lt_entries = zcl_hithub_timeline=>list(
      iv_subject_type = zcl_hithub_timeline=>c_pull_request
      iv_subject_id   = 'timeline-pr-1' ).
    ASSERT lines( lt_entries ) = 1.
    READ TABLE lt_entries INDEX 1 INTO DATA(ls_pr_entry).
    ASSERT ls_pr_entry-action = 'merge'.
    ASSERT ls_pr_entry-subject_type = zcl_hithub_timeline=>c_pull_request.
  ENDMETHOD.

  METHOD rejects_other_subject_types.
    DATA(lt_entries) = zcl_hithub_timeline=>list(
      iv_subject_type = 'repository'
      iv_subject_id   = 'timeline-repository-1' ).
    ASSERT lt_entries IS INITIAL.
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
    ASSERT lines( lt_entries ) = 2.
    ASSERT lt_entries[ 1 ]-action = 'repository.create'.
    ASSERT lt_entries[ 2 ]-subject_id = 'activity-issue-1'.
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
    ASSERT lines( lt_entries ) = 2.
    ASSERT lt_entries[ 1 ]-event_id < lt_entries[ 2 ]-event_id.
  ENDMETHOD.

ENDCLASS.
