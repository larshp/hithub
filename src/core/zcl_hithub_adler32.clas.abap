CLASS zcl_hithub_adler32 DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS calculate
      IMPORTING
        iv_data TYPE xstring
      RETURNING
        VALUE(rv_checksum) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_adler32 IMPLEMENTATION.

  METHOD calculate.
    DATA lv_a TYPE int8 VALUE 1.
    DATA lv_b TYPE int8.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_value TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_checksum TYPE int8.
    DATA lv_part TYPE int8.
    DATA lv_output TYPE x LENGTH 1.

    CLEAR rv_checksum.
    WHILE lv_offset < xstrlen( iv_data ).
      lv_byte = iv_data+lv_offset(1).
      lv_value = lv_byte.
      lv_a = ( lv_a + lv_value ) MOD 65521.
      lv_b = ( lv_b + lv_a ) MOD 65521.
      lv_offset = lv_offset + 1.
    ENDWHILE.

    lv_checksum = lv_b * 65536 + lv_a.
    lv_part = lv_checksum DIV 16777216.
    lv_output = lv_part.
    CONCATENATE rv_checksum lv_output INTO rv_checksum IN BYTE MODE.
    lv_checksum = lv_checksum MOD 16777216.
    lv_part = lv_checksum DIV 65536.
    lv_output = lv_part.
    CONCATENATE rv_checksum lv_output INTO rv_checksum IN BYTE MODE.
    lv_checksum = lv_checksum MOD 65536.
    lv_part = lv_checksum DIV 256.
    lv_output = lv_part.
    CONCATENATE rv_checksum lv_output INTO rv_checksum IN BYTE MODE.
    lv_output = lv_checksum MOD 256.
    CONCATENATE rv_checksum lv_output INTO rv_checksum IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
