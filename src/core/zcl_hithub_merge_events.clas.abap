CLASS zcl_hithub_merge_events DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_sink     TYPE REF TO zif_hithub_event_sink
        io_metadata TYPE REF TO zif_hithub_metadata_store.

    METHODS emit_once
      IMPORTING
        iv_actor          TYPE string
        iv_key            TYPE string
        is_event          TYPE zif_hithub_event_sink=>ty_event
      RETURNING
        VALUE(rv_emitted) TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_sink TYPE REF TO zif_hithub_event_sink.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
ENDCLASS.

CLASS zcl_hithub_merge_events IMPLEMENTATION.

  METHOD constructor.
    mo_sink = io_sink.
    mo_metadata = io_metadata.
  ENDMETHOD.

  METHOD emit_once.
    DATA lv_subject_id TYPE string.
    DATA lv_saved TYPE abap_bool.

    CLEAR rv_emitted.
    IF mo_sink IS INITIAL OR mo_metadata IS INITIAL
        OR iv_actor IS INITIAL OR iv_key IS INITIAL
        OR is_event-subject_id IS INITIAL.
      RETURN.
    ENDIF.
    lv_subject_id = mo_metadata->read_idempotency(
      iv_actor = iv_actor iv_key = iv_key ).
    IF lv_subject_id IS NOT INITIAL.
      rv_emitted = abap_true.
      RETURN.
    ENDIF.
    mo_sink->emit( is_event ).
    lv_saved = mo_metadata->save_idempotency(
      iv_actor = iv_actor iv_key = iv_key
      iv_subject_id = is_event-subject_id ).
    rv_emitted = lv_saved.
  ENDMETHOD.

ENDCLASS.
