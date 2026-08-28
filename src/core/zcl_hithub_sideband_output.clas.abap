CLASS zcl_hithub_sideband_output DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS build
      IMPORTING
        iv_data       TYPE xstring
        iv_channel    TYPE i DEFAULT 1
        iv_large_band TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_sideband_output IMPLEMENTATION.

  METHOD build.
    CONSTANTS lc_small_chunk TYPE i VALUE 999.
    CONSTANTS lc_large_chunk TYPE i VALUE 65515.
    DATA lv_chunk_size TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_remaining TYPE i.
    DATA lv_channel_byte TYPE xstring.
    DATA lv_chunk TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_packet TYPE xstring.

    CLEAR rv_response.
    IF iv_channel < 1 OR iv_channel > 3.
      RETURN.
    ENDIF.
    IF iv_large_band = abap_true.
      lv_chunk_size = lc_large_chunk.
    ELSE.
      lv_chunk_size = lc_small_chunk.
    ENDIF.
    lv_channel_byte = iv_channel.
    lv_remaining = xstrlen( iv_data ).
    WHILE lv_offset < xstrlen( iv_data ).
      lv_remaining = xstrlen( iv_data ) - lv_offset.
      IF lv_remaining > lv_chunk_size.
        lv_remaining = lv_chunk_size.
      ENDIF.
      lv_chunk = iv_data+lv_offset(lv_remaining).
      CONCATENATE lv_channel_byte lv_chunk INTO lv_payload IN BYTE MODE.
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
      IF lv_packet IS INITIAL.
        CLEAR rv_response.
        RETURN.
      ENDIF.
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
      lv_offset = lv_offset + lv_remaining.
    ENDWHILE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
