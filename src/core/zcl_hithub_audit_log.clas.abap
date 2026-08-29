CLASS zcl_hithub_audit_log DEFINITION
  PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS record
      IMPORTING
        io_sink         TYPE REF TO zif_hithub_event_sink
        io_context      TYPE REF TO zif_hithub_rest_context
        iv_action       TYPE string
        iv_subject_type TYPE string
        iv_subject_id   TYPE string
        iv_details      TYPE string OPTIONAL
      RAISING cx_static_check.
ENDCLASS.

CLASS zcl_hithub_audit_log IMPLEMENTATION.
  METHOD record.
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.
    IF io_sink IS INITIAL OR io_context IS INITIAL.
      RETURN.
    ENDIF.
    ls_event-actor = io_context->actor_label( ).
    ls_event-action = iv_action.
    ls_event-subject_type = iv_subject_type.
    ls_event-subject_id = iv_subject_id.
    ls_event-correlation_id = io_context->correlation_id( ).
    GET TIME STAMP FIELD ls_event-occurred_at.
    ls_event-details = iv_details.
    io_sink->emit( ls_event ).
  ENDMETHOD.
ENDCLASS.
