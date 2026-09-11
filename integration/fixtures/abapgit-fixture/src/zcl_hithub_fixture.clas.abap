CLASS zcl_hithub_fixture DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS value
      RETURNING
        VALUE(rv_value) TYPE string.

ENDCLASS.

CLASS zcl_hithub_fixture IMPLEMENTATION.

  METHOD value.
    rv_value = 'abapGit fixture'.
  ENDMETHOD.

ENDCLASS.
