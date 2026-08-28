CLASS zcl_hithub_pack_header DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_header,
        signature    TYPE string,
        version      TYPE i,
        object_count TYPE i,
      END OF ty_header.

    CLASS-METHODS parse
      IMPORTING
        iv_data TYPE xstring
      RETURNING
        VALUE(rs_header) TYPE ty_header.

    CLASS-METHODS build
      IMPORTING
        iv_object_count TYPE i
      RETURNING
        VALUE(rv_data) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_pack_header IMPLEMENTATION.

  METHOD build.
    CONSTANTS lc_pack TYPE x LENGTH 4 VALUE '5041434B'.
    CONSTANTS lc_version TYPE x LENGTH 4 VALUE '00000002'.
    DATA lv_remaining TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_first TYPE x LENGTH 1.
    DATA lv_second TYPE x LENGTH 1.
    DATA lv_third TYPE x LENGTH 1.
    DATA lv_fourth TYPE x LENGTH 1.

    CLEAR rv_data.
    IF iv_object_count < 0.
      RETURN.
    ENDIF.
    lv_remaining = iv_object_count.
    lv_first = lv_remaining DIV 16777216.
    lv_remaining = lv_remaining MOD 16777216.
    lv_second = lv_remaining DIV 65536.
    lv_remaining = lv_remaining MOD 65536.
    lv_third = lv_remaining DIV 256.
    lv_fourth = lv_remaining MOD 256.
    lv_byte = lv_fourth.
    CONCATENATE lc_pack lc_version lv_first lv_second lv_third lv_byte
      INTO rv_data IN BYTE MODE.
  ENDMETHOD.

  METHOD parse.
    DATA lv_version TYPE i.
    DATA lv_object_count TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_value TYPE i.
    DATA lv_offset TYPE i.

    CLEAR rs_header.
    IF xstrlen( iv_data ) < 12 OR iv_data+0(4) <> CONV xstring( '5041434B' ).
      RETURN.
    ENDIF.

    lv_offset = 4.
    DO 4 TIMES.
      lv_byte = iv_data+lv_offset(1).
      lv_value = lv_byte.
      lv_version = lv_version * 256 + lv_value.
      lv_offset = lv_offset + 1.
    ENDDO.
    IF lv_version <> 2.
      RETURN.
    ENDIF.

    DO 4 TIMES.
      lv_byte = iv_data+lv_offset(1).
      lv_value = lv_byte.
      lv_object_count = lv_object_count * 256 + lv_value.
      lv_offset = lv_offset + 1.
    ENDDO.

    rs_header-signature = 'PACK'.
    rs_header-version = lv_version.
    rs_header-object_count = lv_object_count.
  ENDMETHOD.

ENDCLASS.
