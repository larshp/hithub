CLASS ltcl_local_event_sink DEFINITION
  FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS persists_sanitized_event FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_local_event_sink IMPLEMENTATION.
  METHOD persists_sanitized_event.
    DATA(lo_sink) = NEW zcl_hithub_local_event_sink( ).
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.
    DATA lv_event_id TYPE string.
    ls_event-actor = 'local-development'.
    ls_event-action = 'repository.create'.
    ls_event-subject_type = 'repository'.
    ls_event-subject_id = 'audit-repository'.
    ls_event-correlation_id = 'audit-correlation'.
    ls_event-occurred_at = '20260828123456.0000000'.
    ls_event-details = 'name=audit-repository'.
    lo_sink->zif_hithub_event_sink~emit( ls_event ).
    SELECT SINGLE event_id FROM zhi_event INTO @lv_event_id
      WHERE subject_id = @ls_event-subject_id.
    ASSERT sy-subrc = 0.
    ASSERT lv_event_id IS NOT INITIAL.
  ENDMETHOD.
ENDCLASS.
