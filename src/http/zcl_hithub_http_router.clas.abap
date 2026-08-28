CLASS zcl_hithub_http_router DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_route.
    TYPES   kind TYPE string.
    TYPES   repository_name TYPE string.
    TYPES   service TYPE string.
    TYPES END OF ty_route.

    CLASS-METHODS resolve
      IMPORTING
        iv_path TYPE string
        iv_service TYPE string
      RETURNING
        VALUE(rs_route) TYPE ty_route.
ENDCLASS.

CLASS zcl_hithub_http_router IMPLEMENTATION.

  METHOD resolve.
    CLEAR rs_route.

    IF iv_path = '/health' OR iv_path IS INITIAL.
      rs_route-kind = 'health'.
      RETURN.
    ENDIF.

    FIND REGEX '^/(.*)\.git/git-upload-pack$' IN iv_path
      SUBMATCHES rs_route-repository_name.
    IF sy-subrc = 0 AND rs_route-repository_name IS NOT INITIAL.
      rs_route-kind = 'git-upload-pack'.
      rs_route-service = 'git-upload-pack'.
      RETURN.
    ENDIF.

    FIND REGEX '^/(.*)\.git/git-receive-pack$' IN iv_path
      SUBMATCHES rs_route-repository_name.
    IF sy-subrc = 0 AND rs_route-repository_name IS NOT INITIAL.
      rs_route-kind = 'git-receive-pack'.
      rs_route-service = 'git-receive-pack'.
      RETURN.
    ENDIF.

    IF iv_service = 'git-upload-pack'
        OR iv_service = 'git-receive-pack'.
      FIND REGEX '^/(.*)\.git/info/refs$' IN iv_path
        SUBMATCHES rs_route-repository_name.
      IF sy-subrc = 0 AND rs_route-repository_name IS NOT INITIAL.
        rs_route-kind = 'git-discovery'.
        rs_route-service = iv_service.
        RETURN.
      ENDIF.
    ENDIF.

    IF iv_path CP '/api/*'.
      rs_route-kind = 'rest'.
      RETURN.
    ENDIF.

    rs_route-kind = 'not-found'.
  ENDMETHOD.

ENDCLASS.
