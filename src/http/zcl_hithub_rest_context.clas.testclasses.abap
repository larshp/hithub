CLASS ltcl_hithub_rest_context DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS preserves_request_values FOR TESTING RAISING cx_static_check.
    METHODS supplies_fixed_local_actor FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_hithub_rest_context IMPLEMENTATION.

  METHOD preserves_request_values.
    DATA(lo_context) = NEW zcl_hithub_rest_context(
      iv_method          = 'patch'
      iv_path            = '/api/repos/demo'
      iv_body            = CONV xstring( '7B226E616D65223A2264656D6F227D' )
      iv_actor_label     = 'trusted-actor'
      iv_correlation_id  = 'request-123'
      iv_idempotency_key = 'retry-123'
      iv_if_match        = '"7"' ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~request_method( )
      exp = 'PATCH' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~path( )
      exp = '/api/repos/demo' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~body( )
      exp = CONV xstring( '7B226E616D65223A2264656D6F227D' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~actor_label( )
      exp = 'trusted-actor' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~correlation_id( )
      exp = 'request-123' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~idempotency_key( )
      exp = 'retry-123' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->zif_hithub_rest_context~if_match( )
      exp = '"7"' ).
  ENDMETHOD.

  METHOD supplies_fixed_local_actor.
    DATA(lo_context) = zcl_hithub_rest_context=>for_local(
      iv_method = 'get' iv_path = '/api/repos' ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_context->actor_label( )
      exp = 'local-development' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_context->request_method( )
      exp = 'GET' ).
  ENDMETHOD.

ENDCLASS.
