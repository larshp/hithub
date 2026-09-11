CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS builds_discovery_packets FOR TESTING RAISING cx_static_check.
    METHODS builds_receive_discovery FOR TESTING RAISING cx_static_check.
    METHODS rejects_wrong_service FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD builds_discovery_packets.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_body TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_head_oid TYPE string.
    DATA lv_nul TYPE xstring.

    lv_head_oid = '1111111111111111111111111111111111111111'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-oid = lv_head_oid.
    APPEND ls_reference TO lt_references.
    lv_body = zcl_hithub_upload_discovery=>build(
      iv_service    = 'git-upload-pack'
      iv_head_oid   = lv_head_oid
      iv_head_ref   = 'refs/heads/main'
      it_references = lt_references ).

    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_body ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_packet-payload
      exp = cl_abap_codepage=>convert_to(
        source = '# service=git-upload-pack' && cl_abap_char_utilities=>newline ) ).
    lv_rest = lv_body+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'flush' ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'data' ).
    lv_nul = CONV xstring( '00' ).
    FIND lv_nul IN ls_packet-payload IN BYTE MODE.
    cl_abap_unit_assert=>assert_subrc( ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'data' ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'flush' ).
  ENDMETHOD.

  METHOD builds_receive_discovery.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_oid TYPE string.
    DATA lv_body TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_rest TYPE xstring.
    DATA lv_nul TYPE xstring.
    DATA lv_report_status TYPE xstring.

    lv_oid = '1111111111111111111111111111111111111111'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-oid = lv_oid.
    APPEND ls_reference TO lt_references.
    lv_body = zcl_hithub_upload_discovery=>build(
      iv_service    = 'git-receive-pack'
      iv_head_oid   = lv_oid
      iv_head_ref   = 'refs/heads/main'
      it_references = lt_references ).

    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_body ).
    cl_abap_unit_assert=>assert_true( act = ls_packet-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_packet-payload
      exp = cl_abap_codepage=>convert_to(
        source = '# service=git-receive-pack' && cl_abap_char_utilities=>newline ) ).
    lv_rest = lv_body+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    cl_abap_unit_assert=>assert_equals( act = ls_packet-kind exp = 'flush' ).
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    lv_nul = CONV xstring( '00' ).
    FIND lv_nul IN ls_packet-payload IN BYTE MODE.
    cl_abap_unit_assert=>assert_subrc( ).
    lv_report_status = cl_abap_codepage=>convert_to( source = 'report-status' ).
    FIND lv_report_status IN ls_packet-payload IN BYTE MODE.
    cl_abap_unit_assert=>assert_subrc( ).
  ENDMETHOD.

  METHOD rejects_wrong_service.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.

    cl_abap_unit_assert=>assert_initial(
      act = zcl_hithub_upload_discovery=>build(
        iv_service    = 'git-upload-archive'
        iv_head_oid   = '1111111111111111111111111111111111111111'
        iv_head_ref   = 'refs/heads/main'
        it_references = lt_references ) ).
  ENDMETHOD.

ENDCLASS.
