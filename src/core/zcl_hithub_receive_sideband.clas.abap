CLASS zcl_hithub_receive_sideband DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS build
      IMPORTING
        iv_status TYPE xstring
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_receive_sideband IMPLEMENTATION.

  METHOD build.
    DATA lv_remaining TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_channel TYPE xstring.
    DATA lv_inner_flush TYPE xstring.
    DATA lv_flush TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    CLEAR rv_response.
    lv_remaining = iv_status.
    lv_channel = CONV xstring( '01' ).
    lv_inner_flush = zcl_hithub_pkt_line_codec=>flush( ).
    WHILE xstrlen( lv_remaining ) > 0.
      ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_remaining ).
      IF ls_packet-valid = abap_false.
        CLEAR rv_response.
        RETURN.
      ENDIF.
      IF ls_packet-kind = 'data'.
        lv_payload = lv_remaining+0(ls_packet-consumed_bytes).
      ELSEIF ls_packet-kind = 'flush'.
        lv_payload = lv_inner_flush.
      ELSE.
        CLEAR rv_response.
        RETURN.
      ENDIF.
      CONCATENATE lv_channel lv_payload INTO lv_payload IN BYTE MODE.
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
      IF lv_packet IS INITIAL.
        CLEAR rv_response.
        RETURN.
      ENDIF.
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
      lv_remaining = lv_remaining+ls_packet-consumed_bytes.
    ENDWHILE.
    lv_flush = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_response lv_flush INTO rv_response IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
