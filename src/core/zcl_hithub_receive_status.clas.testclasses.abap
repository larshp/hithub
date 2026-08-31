CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS builds_success_status FOR TESTING RAISING cx_static_check.
    METHODS builds_rejection_status FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD builds_success_status.
    DATA lt_results TYPE zcl_hithub_receive_status=>ty_results.
    DATA ls_result TYPE zcl_hithub_receive_status=>ty_result.
    DATA lv_response TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    ls_result-ref_name = 'refs/heads/main'.
    ls_result-ok = abap_true.
    APPEND ls_result TO lt_results.
    lv_response = zcl_hithub_receive_status=>build(
      iv_unpack_ok = abap_true it_results = lt_results ).

    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT cl_abap_codepage=>convert_from( ls_packet-payload ) =
      'unpack ok' && cl_abap_char_utilities=>newline.
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT cl_abap_codepage=>convert_from( ls_packet-payload ) =
      'ok refs/heads/main' && cl_abap_char_utilities=>newline.
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-kind = 'flush'.
  ENDMETHOD.

  METHOD builds_rejection_status.
    DATA lt_results TYPE zcl_hithub_receive_status=>ty_results.
    DATA ls_result TYPE zcl_hithub_receive_status=>ty_result.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_expected TYPE string.
    DATA lv_rest TYPE xstring.

    ls_result-ref_name = 'refs/heads/main'.
    ls_result-ok = abap_false.
    ls_result-reason = 'stale old oid'.
    APPEND ls_result TO lt_results.
    lv_response = zcl_hithub_receive_status=>build(
      iv_unpack_ok = abap_true it_results = lt_results ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    lv_expected = 'ng refs/heads/main stale old oid' &&
      cl_abap_char_utilities=>newline.
    ASSERT cl_abap_codepage=>convert_from( ls_packet-payload ) = lv_expected.
  ENDMETHOD.

ENDCLASS.
