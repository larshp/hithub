CLASS zcl_hithub_pkt_line_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_packet,
        kind           TYPE string,
        payload        TYPE xstring,
        length         TYPE i,
        consumed_bytes TYPE i,
        valid          TYPE abap_bool,
      END OF ty_packet.

    CLASS-METHODS encode
      IMPORTING
        iv_payload TYPE xstring
      RETURNING
        VALUE(rv_packet) TYPE xstring.

    CLASS-METHODS flush
      RETURNING
        VALUE(rv_packet) TYPE xstring.

    CLASS-METHODS decode
      IMPORTING
        iv_data TYPE xstring
      RETURNING
        VALUE(rs_packet) TYPE ty_packet.

    CLASS-METHODS hex_digit
      IMPORTING
        iv_char TYPE string
      RETURNING
        VALUE(rv_value) TYPE i.

ENDCLASS.

CLASS zcl_hithub_pkt_line_codec IMPLEMENTATION.

  METHOD encode.
    CONSTANTS lc_max_payload TYPE i VALUE 65516.
    CONSTANTS lc_hex_digits TYPE string VALUE '0123456789abcdef'.
    DATA lv_length TYPE i.
    DATA lv_nibble TYPE i.
    DATA lv_header TYPE string.
    DATA lv_header_bytes TYPE xstring.

    CLEAR rv_packet.
    IF xstrlen( iv_payload ) > lc_max_payload.
      RETURN.
    ENDIF.

    lv_length = xstrlen( iv_payload ) + 4.
    lv_nibble = lv_length DIV 4096.
    lv_header = lc_hex_digits+lv_nibble(1).
    lv_length = lv_length MOD 4096.
    lv_nibble = lv_length DIV 256.
    lv_header = lv_header && lc_hex_digits+lv_nibble(1).
    lv_length = lv_length MOD 256.
    lv_nibble = lv_length DIV 16.
    lv_header = lv_header && lc_hex_digits+lv_nibble(1).
    lv_nibble = lv_length MOD 16.
    lv_header = lv_header && lc_hex_digits+lv_nibble(1).

    lv_header_bytes = cl_abap_codepage=>convert_to( source = lv_header ).
    CONCATENATE lv_header_bytes iv_payload INTO rv_packet IN BYTE MODE.
  ENDMETHOD.

  METHOD flush.
    rv_packet = cl_abap_codepage=>convert_to( source = '0000' ).
  ENDMETHOD.

  METHOD decode.
    DATA lv_header TYPE xstring.
    DATA lv_header_text TYPE string.
    DATA lv_length TYPE i.
    DATA lv_digit TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_char TYPE string.
    DATA lv_payload_length TYPE i.

    CLEAR rs_packet.
    IF xstrlen( iv_data ) < 4.
      RETURN.
    ENDIF.
    lv_header = iv_data+0(4).
    lv_header_text = cl_abap_codepage=>convert_from( source = lv_header ).
    DO 4 TIMES.
      lv_char = lv_header_text+lv_offset(1).
      lv_digit = hex_digit( lv_char ).
      IF lv_digit < 0.
        RETURN.
      ENDIF.
      lv_length = lv_length * 16 + lv_digit.
      lv_offset = lv_offset + 1.
    ENDDO.

    rs_packet-length = lv_length.
    CASE lv_length.
      WHEN 0.
        rs_packet-kind = 'flush'.
        rs_packet-valid = abap_true.
        rs_packet-consumed_bytes = 4.
        RETURN.
      WHEN 1.
        rs_packet-kind = 'delim'.
        rs_packet-valid = abap_true.
        rs_packet-consumed_bytes = 4.
        RETURN.
      WHEN 2.
        rs_packet-kind = 'response-end'.
        rs_packet-valid = abap_true.
        rs_packet-consumed_bytes = 4.
        RETURN.
      WHEN 3.
        RETURN.
    ENDCASE.

    IF lv_length < 4 OR lv_length > xstrlen( iv_data ).
      CLEAR rs_packet.
      RETURN.
    ENDIF.
    lv_payload_length = lv_length - 4.
    IF lv_payload_length > 0.
      rs_packet-payload = iv_data+4(lv_payload_length).
    ENDIF.
    rs_packet-kind = 'data'.
    rs_packet-valid = abap_true.
    rs_packet-consumed_bytes = lv_length.
  ENDMETHOD.

  METHOD hex_digit.
    CASE iv_char.
      WHEN '0'. rv_value = 0.
      WHEN '1'. rv_value = 1.
      WHEN '2'. rv_value = 2.
      WHEN '3'. rv_value = 3.
      WHEN '4'. rv_value = 4.
      WHEN '5'. rv_value = 5.
      WHEN '6'. rv_value = 6.
      WHEN '7'. rv_value = 7.
      WHEN '8'. rv_value = 8.
      WHEN '9'. rv_value = 9.
      WHEN 'a' OR 'A'. rv_value = 10.
      WHEN 'b' OR 'B'. rv_value = 11.
      WHEN 'c' OR 'C'. rv_value = 12.
      WHEN 'd' OR 'D'. rv_value = 13.
      WHEN 'e' OR 'E'. rv_value = 14.
      WHEN 'f' OR 'F'. rv_value = 15.
      WHEN OTHERS. rv_value = -1.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
