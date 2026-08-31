INTERFACE zif_hithub_event_sink
  PUBLIC.

  TYPES:
    BEGIN OF ty_event,
      actor          TYPE string,
      action         TYPE string,
      subject_type   TYPE string,
      subject_id     TYPE string,
      correlation_id TYPE string,
      occurred_at    TYPE timestampl,
      details        TYPE string,
    END OF ty_event.

  METHODS emit
    IMPORTING
      is_event TYPE ty_event
    RAISING
      cx_static_check.

ENDINTERFACE.
