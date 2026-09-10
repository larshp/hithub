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
    DATA lv_expected TYPE string.
    DATA lv_expected_bytes TYPE xstring.
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
    cl_abap_unit_assert=>assert_true(
      act = ls_packet-valid
      msg = 'the outer sideband packet does not decode' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_packet-kind
      exp = 'data'
      msg = 'the outer sideband packet is not a data packet' ).
    lv_channel = ls_packet-payload+0(1).
    cl_abap_unit_assert=>assert_equals(
      act = lv_channel
      exp = CONV xstring( '01' ) ).
    lv_inner = ls_packet-payload+1.
    ls_inner = zcl_hithub_pkt_line_codec=>decode( lv_inner ).
    cl_abap_unit_assert=>assert_true(
      act = ls_inner-valid
      msg = 'the status packet inside band 1 does not decode' ).
    " Compare the bytes first: a mismatch further down then isolates the
    " byte to text conversion rather than the framing.
    lv_expected_bytes = cl_abap_codepage=>convert_to(
      'unpack ok' && cl_abap_char_utilities=>newline ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_inner-payload
      exp = lv_expected_bytes
      msg = 'band 1 does not carry the unpack status line' ).
    lv_expected = cl_abap_codepage=>convert_from( ls_inner-payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_expected
      exp = 'unpack ok' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    lv_channel = ls_packet-payload+0(1).
    cl_abap_unit_assert=>assert_equals(
      act = lv_channel
      exp = CONV xstring( '01' ) ).
  ENDMETHOD.

ENDCLASS.
