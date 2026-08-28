CLASS zcl_abapgit_proxy_config DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor.
    METHODS get_proxy_url
      IMPORTING iv_repo_url TYPE csequence OPTIONAL
      RETURNING VALUE(rv_proxy_url) TYPE string.
    METHODS get_proxy_port
      IMPORTING iv_repo_url TYPE csequence OPTIONAL
      RETURNING VALUE(rv_port) TYPE string.
    METHODS get_proxy_authentication
      IMPORTING iv_repo_url TYPE csequence OPTIONAL
      RETURNING VALUE(rv_auth) TYPE abap_bool.

ENDCLASS.

CLASS zcl_abapgit_proxy_config IMPLEMENTATION.

  METHOD constructor.
  ENDMETHOD.

  METHOD get_proxy_url.
    CLEAR rv_proxy_url.
  ENDMETHOD.

  METHOD get_proxy_port.
    CLEAR rv_port.
  ENDMETHOD.

  METHOD get_proxy_authentication.
    rv_auth = abap_false.
  ENDMETHOD.

ENDCLASS.
