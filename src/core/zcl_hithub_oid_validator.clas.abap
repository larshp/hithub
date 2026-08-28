CLASS zcl_hithub_oid_validator DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS is_valid
      IMPORTING
        iv_algorithm TYPE string
        iv_oid       TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_oid_validator IMPLEMENTATION.

  METHOD is_valid.
    DATA lv_algorithm TYPE string.
    DATA lv_length TYPE i.

    CLEAR rv_valid.
    lv_algorithm = iv_algorithm.
    TRANSLATE lv_algorithm TO LOWER CASE.
    CASE lv_algorithm.
      WHEN 'sha1'.
        lv_length = 40.
      WHEN 'sha256'.
        lv_length = 64.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    IF strlen( iv_oid ) <> lv_length.
      RETURN.
    ENDIF.
    FIND REGEX '^[0-9a-f]+$' IN iv_oid.
    IF sy-subrc = 0.
      rv_valid = abap_true.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
