CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS frames_pack_data FOR TESTING RAISING cx_static_check.
    METHODS frames_small_band FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_channel FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD frames_pack_data.
    DATA lv_data TYPE xstring.
    DATA lv_response TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_channel TYPE xstring.
    DATA lv_expected TYPE xstring.

    lv_data = CONV xstring( 'AABBCC' ).
    lv_response = zcl_hithub_sideband_output=>build( lv_data ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    lv_channel = CONV xstring( '01' ).
    CONCATENATE lv_channel lv_data INTO lv_expected IN BYTE MODE.
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_packet-payload
      exp = lv_expected ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'flush' ).
  ENDMETHOD.

  METHOD frames_small_band.
    DATA lv_data TYPE xstring.
    DATA lv_response TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_byte TYPE xstring.

    lv_byte = CONV xstring( 'AA' ).
    DO 2000 TIMES.
      CONCATENATE lv_data lv_byte INTO lv_data IN BYTE MODE.
    ENDDO.
    lv_response = zcl_hithub_sideband_output=>build(
      iv_data = lv_data iv_large_band = abap_false ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( ls_packet-payload )
      exp = 1000 ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( ls_packet-payload )
      exp = 1000 ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( ls_packet-payload )
      exp = 3 ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'flush' ).
  ENDMETHOD.

  METHOD rejects_bad_channel.
    cl_abap_unit_assert=>assert_initial(
      act = zcl_hithub_sideband_output=>build(
        iv_data = CONV xstring( 'AA' ) iv_channel = 4 ) ).
  ENDMETHOD.

ENDCLASS.
