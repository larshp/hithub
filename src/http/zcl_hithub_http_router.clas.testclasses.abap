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
    ASSERT ls_route-kind = 'health'.

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/demo.git/git-upload-pack' iv_service = '' ).
    ASSERT ls_route-kind = 'git-upload-pack'.
    ASSERT ls_route-repository_name = 'demo'.

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/demo.git/git-receive-pack' iv_service = '' ).
    ASSERT ls_route-kind = 'git-receive-pack'.
    ASSERT ls_route-service = 'git-receive-pack'.

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path    = '/demo.git/info/refs'
      iv_service = 'git-upload-pack' ).
    ASSERT ls_route-kind = 'git-discovery'.
    ASSERT ls_route-repository_name = 'demo'.

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/api/repos' iv_service = '' ).
    ASSERT ls_route-kind = 'rest'.

    ls_route = zcl_hithub_http_router=>resolve(
      iv_path = '/demo.git/info/refs' iv_service = 'invalid' ).
    ASSERT ls_route-kind = 'not-found'.
  ENDMETHOD.

ENDCLASS.
