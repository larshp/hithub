CLASS zcl_hithub_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.
ENDCLASS.

CLASS zcl_hithub_http IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_path) = server->request->get_header_field( '~path' ).

    IF lv_path = '/health' OR lv_path IS INITIAL.
      server->response->set_status(
        code   = 200
        reason = 'OK' ).
      server->response->set_content_type( 'application/json' ).
      server->response->set_cdata(
        '{"status":"ok","build":"dev","runtime":"abap",' &&
        '"database":"not-configured"}' ).
    ELSE.
      server->response->set_status(
        code   = 404
        reason = 'Not Found' ).
      server->response->set_content_type( 'application/json' ).
      server->response->set_cdata( '{"status":"not-found"}' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
