CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS returns_nak_without_common FOR TESTING RAISING cx_static_check.
    METHODS returns_detailed_ack FOR TESTING RAISING cx_static_check.
    METHODS returns_basic_ack FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD returns_nak_without_common.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.
    DATA lt_common TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    APPEND '1111111111111111111111111111111111111111' TO ls_request-wants.
    APPEND '2222222222222222222222222222222222222222' TO ls_request-haves.
    lv_response = zcl_hithub_upload_negotiation=>build(
      is_request = ls_request it_common = lt_common ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'NAK' && cl_abap_char_utilities=>newline ).
  ENDMETHOD.

  METHOD returns_detailed_ack.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.
    DATA lt_common TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_oid TYPE string.

    lv_oid = '2222222222222222222222222222222222222222'.
    APPEND lv_oid TO ls_request-wants.
    APPEND lv_oid TO ls_request-haves.
    APPEND 'multi_ack_detailed' TO ls_request-capabilities.
    APPEND lv_oid TO lt_common.
    lv_response = zcl_hithub_upload_negotiation=>build(
      is_request = ls_request it_common = lt_common ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = |ACK { lv_oid } common| && cl_abap_char_utilities=>newline ).
  ENDMETHOD.

  METHOD returns_basic_ack.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.
    DATA lt_common TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_oid TYPE string.

    lv_oid = '3333333333333333333333333333333333333333'.
    APPEND lv_oid TO ls_request-wants.
    APPEND lv_oid TO ls_request-haves.
    APPEND lv_oid TO lt_common.
    lv_response = zcl_hithub_upload_negotiation=>build(
      is_request = ls_request it_common = lt_common ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = |ACK { lv_oid }| && cl_abap_char_utilities=>newline ).
  ENDMETHOD.

ENDCLASS.
