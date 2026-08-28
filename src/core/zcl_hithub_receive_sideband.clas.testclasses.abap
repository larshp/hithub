CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS frames_receive_status FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD frames_receive_status.
    DATA lt_results TYPE zcl_hithub_receive_status=>ty_results.
    DATA ls_result TYPE zcl_hithub_receive_status=>ty_result.
    DATA lv_status TYPE xstring.
    DATA lv_response TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA lv_expected TYPE xstring.
    DATA lv_channel TYPE xstring.
    DATA lv_inner TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA ls_inner TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    ls_result-ref_name = 'refs/heads/main'.
    ls_result-ok = abap_true.
    APPEND ls_result TO lt_results.
    lv_status = zcl_hithub_receive_status=>build(
      iv_unpack_ok = abap_true it_results = lt_results ).
    lv_response = zcl_hithub_receive_sideband=>build( lv_status ).

    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    lv_channel = ls_packet-payload+0(1).
    ASSERT lv_channel = CONV xstring( '01' ).
    lv_inner = ls_packet-payload+1.
    ls_inner = zcl_hithub_pkt_line_codec=>decode( lv_inner ).
    lv_expected = cl_abap_codepage=>convert_from( ls_inner-payload ).
    ASSERT lv_expected = 'unpack ok' && cl_abap_char_utilities=>newline.
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    lv_channel = ls_packet-payload+0(1).
    ASSERT lv_channel = CONV xstring( '01' ).
  ENDMETHOD.

ENDCLASS.
