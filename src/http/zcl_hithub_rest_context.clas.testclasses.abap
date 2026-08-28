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
      iv_method = 'patch'
      iv_path = '/api/repos/demo'
      iv_body = CONV xstring( '7B226E616D65223A2264656D6F227D' )
      iv_actor_label = 'trusted-actor'
      iv_correlation_id = 'request-123'
      iv_idempotency_key = 'retry-123'
      iv_if_match = '"7"' ).

    ASSERT lo_context->zif_hithub_rest_context~request_method( ) = 'PATCH'.
    ASSERT lo_context->zif_hithub_rest_context~path( ) = '/api/repos/demo'.
    ASSERT lo_context->zif_hithub_rest_context~body( ) =
      CONV xstring( '7B226E616D65223A2264656D6F227D' ).
    ASSERT lo_context->zif_hithub_rest_context~actor_label( ) =
      'trusted-actor'.
    ASSERT lo_context->zif_hithub_rest_context~correlation_id( ) =
      'request-123'.
    ASSERT lo_context->zif_hithub_rest_context~idempotency_key( ) =
      'retry-123'.
    ASSERT lo_context->zif_hithub_rest_context~if_match( ) = '"7"'.
  ENDMETHOD.

  METHOD supplies_fixed_local_actor.
    DATA(lo_context) = zcl_hithub_rest_context=>for_local(
      iv_method = 'get' iv_path = '/api/repos' ).

    ASSERT lo_context->actor_label( ) = 'local-development'.
    ASSERT lo_context->request_method( ) = 'GET'.
  ENDMETHOD.

ENDCLASS.
