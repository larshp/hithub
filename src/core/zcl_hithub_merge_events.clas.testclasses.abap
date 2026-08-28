CLASS lcl_merge_event_sink DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_event_sink.
    METHODS count RETURNING VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mv_count TYPE i.
ENDCLASS.

CLASS lcl_merge_event_sink IMPLEMENTATION.

  METHOD zif_hithub_event_sink~emit.
    mv_count = mv_count + 1.
  ENDMETHOD.

  METHOD count.
    rv_count = mv_count.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_merge_events DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS emits_merge_once FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_events IMPLEMENTATION.

  METHOD emits_merge_once.
    DATA lo_sink TYPE REF TO lcl_merge_event_sink.
    DATA lo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA lo_events TYPE REF TO zcl_hithub_merge_events.
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.
    lo_sink = NEW lcl_merge_event_sink( ).
    lo_metadata = NEW zcl_hithub_local_meta_store( ).
    lo_events = NEW zcl_hithub_merge_events(
      io_sink = lo_sink io_metadata = lo_metadata ).
    ls_event-action = 'merge'.
    ls_event-subject_type = 'pull_request'.
    ls_event-subject_id = 'merge-event-request-1'.

    ASSERT lo_events->emit_once(
      iv_actor = 'merge-actor' iv_key = 'merge-key-1'
      is_event = ls_event ) = abap_true.
    ASSERT lo_events->emit_once(
      iv_actor = 'merge-actor' iv_key = 'merge-key-1'
      is_event = ls_event ) = abap_true.
    ASSERT lo_sink->count( ) = 1.
  ENDMETHOD.

ENDCLASS.
