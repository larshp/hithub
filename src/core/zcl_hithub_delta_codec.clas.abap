CLASS zcl_hithub_delta_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS apply
      IMPORTING
        iv_base            TYPE xstring
        iv_delta           TYPE xstring
        iv_max_result_size TYPE int8 DEFAULT 524288000
        iv_delta_depth     TYPE i DEFAULT 0
        iv_max_delta_depth TYPE i DEFAULT 50
      RETURNING
        VALUE(rv_result)   TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_delta_codec IMPLEMENTATION.

  METHOD apply.
    CONSTANTS lc_continue TYPE x LENGTH 1 VALUE '80'.
    CONSTANTS lc_copy TYPE x LENGTH 1 VALUE '80'.
    CONSTANTS lc_zero TYPE x LENGTH 1 VALUE '00'.
    CONSTANTS lc_offset_0 TYPE x LENGTH 1 VALUE '01'.
    CONSTANTS lc_offset_1 TYPE x LENGTH 1 VALUE '02'.
    CONSTANTS lc_offset_2 TYPE x LENGTH 1 VALUE '04'.
    CONSTANTS lc_offset_3 TYPE x LENGTH 1 VALUE '08'.
    CONSTANTS lc_size_0 TYPE x LENGTH 1 VALUE '10'.
    CONSTANTS lc_size_1 TYPE x LENGTH 1 VALUE '20'.
    CONSTANTS lc_size_2 TYPE x LENGTH 1 VALUE '40'.
    DATA lv_offset TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_bits TYPE x LENGTH 1.
    DATA lv_value TYPE i.
    DATA lv_factor TYPE i.
    DATA lv_base_size TYPE i.
    DATA lv_result_size TYPE i.
    DATA lv_copy_offset TYPE i.
    DATA lv_copy_size TYPE i.
    DATA lv_insert_size TYPE i.
    DATA lv_result_length TYPE i.

    CLEAR rv_result.
    IF iv_delta_depth < 0 OR iv_max_delta_depth < 0
        OR iv_delta_depth > iv_max_delta_depth.
      RETURN.
    ENDIF.
    lv_offset = 0.
    DO 2 TIMES.
      IF lv_offset >= xstrlen( iv_delta ).
        RETURN.
      ENDIF.
      lv_factor = 1.
      lv_byte = iv_delta+lv_offset(1).
      lv_bits = lv_byte BIT-AND CONV xstring( '7F' ).
      lv_value = lv_bits.
      IF sy-index = 1.
        lv_base_size = lv_value.
      ELSE.
        lv_result_size = lv_value.
      ENDIF.
      lv_offset = lv_offset + 1.
      WHILE lv_byte BIT-AND lc_continue <> lc_zero.
        IF lv_offset >= xstrlen( iv_delta ).
          CLEAR rv_result.
          RETURN.
        ENDIF.
        lv_byte = iv_delta+lv_offset(1).
        lv_bits = lv_byte BIT-AND CONV xstring( '7F' ).
        lv_value = lv_bits.
        lv_factor = lv_factor * 128.
        IF sy-index = 1.
          lv_base_size = lv_base_size + lv_value * lv_factor.
        ELSE.
          lv_result_size = lv_result_size + lv_value * lv_factor.
        ENDIF.
        lv_offset = lv_offset + 1.
      ENDWHILE.
    ENDDO.
    IF lv_base_size <> xstrlen( iv_base ).
      RETURN.
    ENDIF.
    IF iv_max_result_size < 0 OR lv_result_size > iv_max_result_size.
      RETURN.
    ENDIF.

    WHILE lv_offset < xstrlen( iv_delta ).
      lv_byte = iv_delta+lv_offset(1).
      lv_offset = lv_offset + 1.
      IF lv_byte BIT-AND lc_copy <> lc_zero.
        CLEAR: lv_copy_offset, lv_copy_size.
        lv_factor = 1.
        IF lv_byte BIT-AND lc_offset_0 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_copy_offset = lv_copy_offset + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        IF lv_byte BIT-AND lc_offset_1 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_factor = lv_factor * 256.
          lv_copy_offset = lv_copy_offset + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        IF lv_byte BIT-AND lc_offset_2 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_factor = lv_factor * 256.
          lv_copy_offset = lv_copy_offset + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        IF lv_byte BIT-AND lc_offset_3 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_factor = lv_factor * 256.
          lv_copy_offset = lv_copy_offset + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        lv_factor = 1.
        IF lv_byte BIT-AND lc_size_0 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_copy_size = lv_copy_size + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        IF lv_byte BIT-AND lc_size_1 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_factor = lv_factor * 256.
          lv_copy_size = lv_copy_size + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        IF lv_byte BIT-AND lc_size_2 <> lc_zero.
          IF lv_offset >= xstrlen( iv_delta ).
            CLEAR rv_result.
            RETURN.
          ENDIF.
          lv_bits = iv_delta+lv_offset(1).
          lv_value = lv_bits.
          lv_factor = lv_factor * 256.
          lv_copy_size = lv_copy_size + lv_value * lv_factor.
          lv_offset = lv_offset + 1.
        ENDIF.
        IF lv_copy_size = 0.
          lv_copy_size = 65536.
        ENDIF.
        IF lv_copy_offset + lv_copy_size > xstrlen( iv_base ).
          CLEAR rv_result.
          RETURN.
        ENDIF.
        CONCATENATE rv_result iv_base+lv_copy_offset(lv_copy_size)
          INTO rv_result IN BYTE MODE.
      ELSE.
        lv_insert_size = lv_byte.
        IF lv_insert_size = 0 OR lv_offset + lv_insert_size > xstrlen( iv_delta ).
          CLEAR rv_result.
          RETURN.
        ENDIF.
        CONCATENATE rv_result iv_delta+lv_offset(lv_insert_size)
          INTO rv_result IN BYTE MODE.
        lv_offset = lv_offset + lv_insert_size.
      ENDIF.
      lv_result_length = xstrlen( rv_result ).
      IF lv_result_length > lv_result_size.
        CLEAR rv_result.
        RETURN.
      ENDIF.
    ENDWHILE.
    IF xstrlen( rv_result ) <> lv_result_size.
      CLEAR rv_result.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
