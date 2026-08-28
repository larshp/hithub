CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_v0_request FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_request FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_v0_request.
    DATA lv_data TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA lv_zero TYPE xstring.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.
    DATA lv_oid TYPE string.

    lv_oid = '1111111111111111111111111111111111111111'.
    lv_zero = CONV xstring( '00' ).
    lv_payload = cl_abap_codepage=>convert_to(
      source = |want { lv_oid }| ).
    DATA(lv_caps) = cl_abap_codepage=>convert_to(
      source = 'no-progress side-band-64k' && cl_abap_char_utilities=>newline ).
    CONCATENATE lv_payload lv_zero lv_caps INTO lv_payload IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to(
      source = |have { lv_oid }| && cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to( source = 'deepen 5' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to( source = 'done' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.

    ls_request = zcl_hithub_upload_request=>parse( lv_data ).
    ASSERT ls_request-valid = abap_true.
    ASSERT lines( ls_request-wants ) = 1.
    ASSERT lines( ls_request-haves ) = 1.
    ASSERT ls_request-deepen = 5.
    ASSERT ls_request-saw_flush = abap_true.
    ASSERT ls_request-saw_done = abap_true.
    READ TABLE ls_request-capabilities WITH KEY table_line = 'side-band-64k'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
  ENDMETHOD.

  METHOD rejects_bad_request.
    DATA lv_packet TYPE xstring.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.

    lv_packet = zcl_hithub_pkt_line_codec=>encode(
      cl_abap_codepage=>convert_to( source = 'wat' &&
        cl_abap_char_utilities=>newline ) ).
    ls_request = zcl_hithub_upload_request=>parse( lv_packet ).
    ASSERT ls_request-valid = abap_false.
    ls_request = zcl_hithub_upload_request=>parse(
      cl_abap_codepage=>convert_to( source = '0008abc' ) ).
    ASSERT ls_request-valid = abap_false.
  ENDMETHOD.

ENDCLASS.
