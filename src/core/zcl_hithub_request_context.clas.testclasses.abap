CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS keeps_optional_actor_empty FOR TESTING RAISING cx_static_check.
    METHODS carries_actor_and_correlation FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD keeps_optional_actor_empty.
    DATA(lo_context) = NEW zcl_hithub_request_context( ).

    cl_abap_unit_assert=>assert_initial(
      act = lo_context->zif_hithub_request_context~actor_label( ) ).
    cl_abap_unit_assert=>assert_initial(
      act = lo_context->zif_hithub_request_context~correlation_id( ) ).
  ENDMETHOD.

  METHOD carries_actor_and_correlation.
    DATA(lo_context) = NEW zcl_hithub_request_context(
      iv_actor_label    = 'gateway/build-bot'
      iv_correlation_id = 'request-123' ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_request_context~actor_label( )
      exp = 'gateway/build-bot' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_request_context~correlation_id( )
      exp = 'request-123' ).
  ENDMETHOD.

ENDCLASS.
