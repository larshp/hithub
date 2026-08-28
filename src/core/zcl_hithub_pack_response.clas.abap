CLASS zcl_hithub_pack_response DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_output TYPE REF TO zif_hithub_pack_output.

    METHODS stream_pack
      IMPORTING
        iv_pack       TYPE xstring
        iv_large_band TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_packets) TYPE i.

  PRIVATE SECTION.
    DATA mo_output TYPE REF TO zif_hithub_pack_output.

ENDCLASS.

CLASS zcl_hithub_pack_response IMPLEMENTATION.

  METHOD constructor.
    mo_output = io_output.
  ENDMETHOD.

  METHOD stream_pack.
    CONSTANTS lc_small_chunk TYPE i VALUE 999.
    CONSTANTS lc_large_chunk TYPE i VALUE 65515.
    DATA lv_chunk_size TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_remaining TYPE i.
    DATA lv_channel TYPE xstring.
    DATA lv_chunk TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_packet TYPE xstring.

    CLEAR rv_packets.
    IF mo_output IS INITIAL.
      RETURN.
    ENDIF.
    IF iv_large_band = abap_true.
      lv_chunk_size = lc_large_chunk.
    ELSE.
      lv_chunk_size = lc_small_chunk.
    ENDIF.
    lv_channel = CONV xstring( '01' ).
    WHILE lv_offset < xstrlen( iv_pack ).
      lv_remaining = xstrlen( iv_pack ) - lv_offset.
      IF lv_remaining > lv_chunk_size.
        lv_remaining = lv_chunk_size.
      ENDIF.
      lv_chunk = iv_pack+lv_offset(lv_remaining).
      CONCATENATE lv_channel lv_chunk INTO lv_payload IN BYTE MODE.
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
      IF lv_packet IS INITIAL.
        RETURN.
      ENDIF.
      mo_output->write( lv_packet ).
      rv_packets = rv_packets + 1.
      lv_offset = lv_offset + lv_remaining.
    ENDWHILE.
    mo_output->write( zcl_hithub_pkt_line_codec=>flush( ) ).
  ENDMETHOD.

ENDCLASS.
