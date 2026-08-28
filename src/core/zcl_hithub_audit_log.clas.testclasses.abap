CLASS lcl_audit_capture DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_hithub_event_sink.
    METHODS event RETURNING VALUE(rs_event) TYPE zif_hithub_event_sink=>ty_event.
  PRIVATE SECTION.
    DATA ms_event TYPE zif_hithub_event_sink=>ty_event.
ENDCLASS.

CLASS lcl_audit_capture IMPLEMENTATION.
  METHOD zif_hithub_event_sink~emit.
    ms_event = is_event.
  ENDMETHOD.
  METHOD event.
    rs_event = ms_event.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_audit_log DEFINITION
  FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS propagates_actor_context FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_audit_log IMPLEMENTATION.
  METHOD propagates_actor_context.
    DATA(lo_sink) = NEW lcl_audit_capture( ).
    DATA(lo_context) = zcl_hithub_rest_context=>for_local(
      iv_method = 'POST' iv_path = '/api/repos'
      iv_correlation_id = 'audit-correlation' ).
    zcl_hithub_audit_log=>record(
      io_sink = lo_sink io_context = lo_context
      iv_action = 'repository.create' iv_subject_type = 'repository'
      iv_subject_id = 'audit-repository' ).
    DATA(ls_event) = lo_sink->event( ).
    ASSERT ls_event-actor = 'local-development'.
    ASSERT ls_event-correlation_id = 'audit-correlation'.
    ASSERT ls_event-action = 'repository.create'.
  ENDMETHOD.
ENDCLASS.
