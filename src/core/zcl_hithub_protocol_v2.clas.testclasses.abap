CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS advertises_version_and_agent FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD advertises_version_and_agent.
    DATA lv_response TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    lv_response = zcl_hithub_protocol_v2=>advertise( ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'version 2' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'agent=hithub' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'ls-refs' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'fetch=shallow' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-kind = 'flush'.
  ENDMETHOD.

ENDCLASS.
