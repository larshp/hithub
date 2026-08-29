CLASS zcl_hithub_request_context DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_request_context.

    METHODS constructor
      IMPORTING
        iv_actor_label    TYPE string OPTIONAL
        iv_correlation_id TYPE string OPTIONAL.

  PRIVATE SECTION.
    DATA mv_actor_label TYPE string.
    DATA mv_correlation_id TYPE string.

ENDCLASS.

CLASS zcl_hithub_request_context IMPLEMENTATION.

  METHOD constructor.
    " The actor value is supplied by a trusted SAP/gateway adapter. This
    " object intentionally has no API that reads arbitrary client headers.
    mv_actor_label = iv_actor_label.
    mv_correlation_id = iv_correlation_id.
  ENDMETHOD.

  METHOD zif_hithub_request_context~actor_label.
    rv_actor = mv_actor_label.
  ENDMETHOD.

  METHOD zif_hithub_request_context~correlation_id.
    rv_correlation_id = mv_correlation_id.
  ENDMETHOD.

ENDCLASS.
