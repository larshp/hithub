CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_commands_and_pack FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_receive_line FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_commands_and_pack.
    DATA lv_data TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA lv_old_oid TYPE string.
    DATA lv_new_oid TYPE string.
    DATA lv_zero TYPE xstring.
    DATA lv_pack TYPE xstring.
    DATA ls_request TYPE zcl_hithub_receive_request=>ty_request.

    lv_old_oid = '0000000000000000000000000000000000000000'.
    lv_new_oid = '1111111111111111111111111111111111111111'.
    lv_zero = CONV xstring( '00' ).
    lv_pack = CONV xstring( '5041434b' ).
    lv_payload = cl_abap_codepage=>convert_to(
      source = |{ lv_old_oid } { lv_new_oid } refs/heads/main| ).
    DATA(lv_caps) = cl_abap_codepage=>convert_to(
      source = 'report-status side-band-64k' && cl_abap_char_utilities=>newline ).
    CONCATENATE lv_payload lv_zero lv_caps
      INTO lv_payload IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_payload = cl_abap_codepage=>convert_to(
      source = |{ lv_new_oid } { lv_new_oid } refs/tags/v1| &&
        cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    CONCATENATE lv_data lv_pack INTO lv_data IN BYTE MODE.

    ls_request = zcl_hithub_receive_request=>parse( lv_data ).
    ASSERT ls_request-valid = abap_true.
    ASSERT lines( ls_request-commands ) = 2.
    ASSERT ls_request-commands[ 1 ]-old_oid = lv_old_oid.
    ASSERT ls_request-commands[ 1 ]-new_oid = lv_new_oid.
    ASSERT ls_request-commands[ 1 ]-ref_name = 'refs/heads/main'.
    ASSERT ls_request-commands[ 2 ]-ref_name = 'refs/tags/v1'.
    ASSERT ls_request-pack = CONV xstring( '5041434b' ).
    READ TABLE ls_request-capabilities WITH KEY table_line = 'report-status'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
  ENDMETHOD.

  METHOD rejects_bad_receive_line.
    DATA lv_payload TYPE xstring.
    DATA lv_data TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA ls_request TYPE zcl_hithub_receive_request=>ty_request.

    lv_payload = cl_abap_codepage=>convert_to(
      source = 'bad command' && cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.

    ls_request = zcl_hithub_receive_request=>parse( lv_data ).
    ASSERT ls_request-valid = abap_false.
  ENDMETHOD.

ENDCLASS.
