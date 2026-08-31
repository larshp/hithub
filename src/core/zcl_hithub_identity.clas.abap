CLASS zcl_hithub_identity DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS is_valid
      IMPORTING
        iv_identity     TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.
ENDCLASS.

CLASS zcl_hithub_identity IMPLEMENTATION.

  METHOD is_valid.
    CLEAR rv_valid.
    IF iv_identity IS INITIAL OR iv_identity CS cl_abap_char_utilities=>newline.
      RETURN.
    ENDIF.
    FIND REGEX '^.+ <[^ <>]+@[^ <>]+> [0-9]+ [+-][0-9]{4}$'
      IN iv_identity.
    rv_valid = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

ENDCLASS.
