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
      iv_service = 'git-upload-pack'
      iv_head_oid = lv_head_oid
      iv_head_ref = 'refs/heads/main'
      it_references = lt_references ).

    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_body ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = '# service=git-upload-pack' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_body+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-kind = 'flush'.
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-kind = 'data'.
    lv_nul = CONV xstring( '00' ).
    ASSERT ls_packet-payload CS lv_nul.
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-kind = 'data'.
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-kind = 'flush'.
  ENDMETHOD.

  METHOD builds_receive_discovery.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_oid TYPE string.
    DATA lv_body TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_rest TYPE xstring.

    lv_oid = '1111111111111111111111111111111111111111'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-oid = lv_oid.
    APPEND ls_reference TO lt_references.
    lv_body = zcl_hithub_upload_discovery=>build(
      iv_service = 'git-receive-pack'
      iv_head_oid = lv_oid
      iv_head_ref = 'refs/heads/main'
      it_references = lt_references ).

    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_body ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = '# service=git-receive-pack' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_body+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-kind = 'flush'.
    lv_rest = lv_rest+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-payload CS CONV xstring( '00' ).
    ASSERT ls_packet-payload CS cl_abap_codepage=>convert_to(
      source = 'report-status' ).
  ENDMETHOD.

  METHOD rejects_wrong_service.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.

    ASSERT zcl_hithub_upload_discovery=>build(
      iv_service = 'git-upload-archive'
      iv_head_oid = '1111111111111111111111111111111111111111'
      iv_head_ref = 'refs/heads/main'
      it_references = lt_references ) IS INITIAL.
  ENDMETHOD.

ENDCLASS.
