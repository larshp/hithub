CLASS ltcl_http_router DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS classifies_http_routes FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_http_router IMPLEMENTATION.

  METHOD classifies_http_routes.
    DATA(ls_route) = zcl_hithub_http_router=>resolve(
      iv_path = '/health' iv_service = '' ).
    cl_abap_unit_assert=>assert_equals( act = ls_route-kind exp = 'health' ).

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/demo.git/git-upload-pack' iv_service = '' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_route-kind
      exp = 'git-upload-pack' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_route-repository_name
      exp = 'demo' ).

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/demo.git/git-receive-pack' iv_service = '' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_route-kind
      exp = 'git-receive-pack' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_route-service
      exp = 'git-receive-pack' ).

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path    = '/demo.git/info/refs'
      iv_service = 'git-upload-pack' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_route-kind
      exp = 'git-discovery' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_route-repository_name
      exp = 'demo' ).

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/api/repos' iv_service = '' ).
    cl_abap_unit_assert=>assert_equals( act = ls_route-kind exp = 'rest' ).

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/demo.git/info/refs' iv_service = 'invalid' ).
    cl_abap_unit_assert=>assert_equals( act = ls_route-kind exp = 'not-found' ).
  ENDMETHOD.

ENDCLASS.
