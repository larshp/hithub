CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_fetch_request FOR TESTING RAISING cx_static_check.
    METHODS builds_packfile_response FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_fetch FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_fetch_request.
    DATA lv_data TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA lv_delim TYPE xstring.
    DATA ls_request TYPE zcl_hithub_v2_fetch=>ty_request.
    DATA lv_oid TYPE string.

    lv_oid = '1111111111111111111111111111111111111111'.
    lv_payload = cl_abap_codepage=>convert_to( source = 'command=fetch' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to( source = 'agent=git/2.43.0' ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_delim = cl_abap_codepage=>convert_to( source = '0001' ).
    CONCATENATE lv_data lv_delim INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to( source = |want { lv_oid }| &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to( source = 'ofs-delta' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to( source = 'done' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.

    ls_request = zcl_hithub_v2_fetch=>parse( lv_data ).
    ASSERT ls_request-valid = abap_true.
    ASSERT lines( ls_request-wants ) = 1.
    ASSERT ls_request-saw_done = abap_true.
    READ TABLE ls_request-features WITH KEY table_line = 'ofs-delta'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
  ENDMETHOD.

  METHOD builds_packfile_response.
    DATA lv_pack TYPE xstring.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_rest TYPE xstring.
    DATA lv_channel TYPE xstring.

    lv_pack = CONV xstring( '5041434B' ).
    lv_response = zcl_hithub_v2_fetch=>build_response( lv_pack ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'packfile' && cl_abap_char_utilities=>newline ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    lv_channel = CONV xstring( '01' ).
    ASSERT ls_packet-payload = lv_channel && lv_pack.
  ENDMETHOD.

  METHOD rejects_invalid_fetch.
    DATA ls_request TYPE zcl_hithub_v2_fetch=>ty_request.

    ls_request = zcl_hithub_v2_fetch=>parse(
      cl_abap_codepage=>convert_to( source = '0004' ) ).
    ASSERT ls_request-valid = abap_false.
  ENDMETHOD.

ENDCLASS.
