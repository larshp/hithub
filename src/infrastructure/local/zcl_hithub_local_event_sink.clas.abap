CLASS zcl_hithub_local_event_sink DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_hithub_event_sink.
ENDCLASS.

CLASS zcl_hithub_local_event_sink IMPLEMENTATION.
  METHOD zif_hithub_event_sink~emit.
    DATA ls_row TYPE zhi_event.
    DATA lv_event_id TYPE sysuuid_c36.
    lv_event_id = cl_system_uuid=>if_system_uuid_static~create_uuid_c36( ).
    ls_row-event_id = lv_event_id.
    ls_row-actor = is_event-actor.
    ls_row-action = is_event-action.
    ls_row-subject_type = is_event-subject_type.
    ls_row-subject_id = is_event-subject_id.
    ls_row-correlation_id = is_event-correlation_id.
    ls_row-occurred_at = is_event-occurred_at.
    IF ls_row-occurred_at IS INITIAL.
      GET TIME STAMP FIELD ls_row-occurred_at.
    ENDIF.
    ls_row-details = is_event-details.
    INSERT zhi_event FROM @ls_row.
  ENDMETHOD.
ENDCLASS.
