CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS keeps_optional_actor_empty FOR TESTING RAISING cx_static_check.
    METHODS carries_actor_and_correlation FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD keeps_optional_actor_empty.
    DATA(lo_context) = NEW zcl_hithub_request_context( ).

    ASSERT lo_context->zif_hithub_request_context~actor_label( ) IS INITIAL.
    ASSERT lo_context->zif_hithub_request_context~correlation_id( ) IS INITIAL.
  ENDMETHOD.

  METHOD carries_actor_and_correlation.
    DATA(lo_context) = NEW zcl_hithub_request_context(
      iv_actor_label = 'gateway/build-bot'
      iv_correlation_id = 'request-123' ).

    ASSERT lo_context->zif_hithub_request_context~actor_label( ) =
      'gateway/build-bot'.
    ASSERT lo_context->zif_hithub_request_context~correlation_id( ) =
      'request-123'.
  ENDMETHOD.

ENDCLASS.
