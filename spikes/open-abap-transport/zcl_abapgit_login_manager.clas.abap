CLASS zcl_abapgit_login_manager DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_username
      IMPORTING iv_url TYPE string
      RETURNING VALUE(rv_username) TYPE string.
    CLASS-METHODS get_password
      IMPORTING iv_url TYPE string
      RETURNING VALUE(rv_password) TYPE string.
    CLASS-METHODS load
      IMPORTING iv_url TYPE string
      RETURNING VALUE(rv_authorization) TYPE string.
    CLASS-METHODS save
      IMPORTING iv_uri TYPE string iv_authorization TYPE string.
    CLASS-METHODS remove
      IMPORTING iv_url TYPE string.

ENDCLASS.

CLASS zcl_abapgit_login_manager IMPLEMENTATION.

  METHOD get_username.
    CLEAR rv_username.
  ENDMETHOD.

  METHOD get_password.
    CLEAR rv_password.
  ENDMETHOD.

  METHOD load.
    CLEAR rv_authorization.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD remove.
  ENDMETHOD.

ENDCLASS.
