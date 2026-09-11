CLASS zcl_hithub_ref_validator DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS is_valid
      IMPORTING
        iv_ref_name     TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_ref_validator IMPLEMENTATION.

  METHOD is_valid.
    CLEAR rv_valid.
    IF iv_ref_name IS INITIAL OR iv_ref_name = '@'.
      RETURN.
    ENDIF.

    " Git ref names must not contain control characters or these separators.
    FIND REGEX '[[:cntrl:]]' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    FIND REGEX '[ ~^:?*]' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    FIND REGEX '\[' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    FIND REGEX '\\' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    " A slash separates non-empty components; dot components are forbidden.
    FIND REGEX '(^/|/$|//|\.\.|@\{)' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    FIND REGEX '(^|/)\.' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    FIND REGEX '\./|\.$' IN iv_ref_name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    rv_valid = abap_true.
  ENDMETHOD.

ENDCLASS.
