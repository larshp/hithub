CLASS zcl_hithub_pack_arithmetic DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        safe   TYPE abap_bool,
        result TYPE int8,
      END OF ty_result.

    CLASS-METHODS add
      IMPORTING
        iv_left          TYPE int8
        iv_right         TYPE int8
      RETURNING
        VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS multiply
      IMPORTING
        iv_left          TYPE int8
        iv_right         TYPE int8
      RETURNING
        VALUE(rs_result) TYPE ty_result.

ENDCLASS.

CLASS zcl_hithub_pack_arithmetic IMPLEMENTATION.

  METHOD add.
    DATA lv_max TYPE int8.

    CLEAR rs_result.
    lv_max = CONV int8( '9223372036854775807' ).
    IF iv_left < 0 OR iv_right < 0 OR iv_left > lv_max - iv_right.
      RETURN.
    ENDIF.
    rs_result-result = iv_left + iv_right.
    rs_result-safe = abap_true.
  ENDMETHOD.

  METHOD multiply.
    DATA lv_max TYPE int8.

    CLEAR rs_result.
    lv_max = CONV int8( '9223372036854775807' ).
    IF iv_left < 0 OR iv_right < 0.
      RETURN.
    ENDIF.
    IF iv_left <> 0 AND iv_right > lv_max DIV iv_left.
      RETURN.
    ENDIF.
    rs_result-result = iv_left * iv_right.
    rs_result-safe = abap_true.
  ENDMETHOD.

ENDCLASS.
