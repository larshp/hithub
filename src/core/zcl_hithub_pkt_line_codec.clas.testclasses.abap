CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS encodes_binary_payload FOR TESTING RAISING cx_static_check.
    METHODS encodes_extended_length FOR TESTING RAISING cx_static_check.
    METHODS distinguishes_empty_and_flush FOR TESTING RAISING cx_static_check.
    METHODS rejects_oversized_payload FOR TESTING RAISING cx_static_check.
    METHODS decodes_binary_packet FOR TESTING RAISING cx_static_check.
    METHODS decodes_packet_stream FOR TESTING RAISING cx_static_check.
    METHODS rejects_malformed_packet FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD encodes_binary_payload.
    DATA lv_payload TYPE xstring.
    DATA lv_header TYPE xstring.
    DATA lv_expected TYPE xstring.

    lv_payload = CONV xstring( 'CAFE00FF' ).
    lv_header = cl_abap_codepage=>convert_to( source = '0008' ).
    CONCATENATE lv_header lv_payload INTO lv_expected IN BYTE MODE.
    ASSERT zcl_hithub_pkt_line_codec=>encode( lv_payload ) = lv_expected.
  ENDMETHOD.

  METHOD encodes_extended_length.
    DATA lv_payload TYPE xstring.
    DATA lv_expected TYPE xstring.
    DATA lv_byte TYPE xstring.
    DATA lv_header TYPE xstring.

    lv_byte = CONV xstring( 'AA' ).
    DO 256 TIMES.
      CONCATENATE lv_payload lv_byte INTO lv_payload IN BYTE MODE.
    ENDDO.
    lv_header = cl_abap_codepage=>convert_to( source = '0104' ).
    CONCATENATE lv_header lv_payload INTO lv_expected IN BYTE MODE.
    ASSERT zcl_hithub_pkt_line_codec=>encode( lv_payload ) = lv_expected.
  ENDMETHOD.

  METHOD distinguishes_empty_and_flush.
    ASSERT zcl_hithub_pkt_line_codec=>encode( CONV xstring( '' ) ) =
      cl_abap_codepage=>convert_to( source = '0004' ).
    ASSERT zcl_hithub_pkt_line_codec=>flush( ) =
      cl_abap_codepage=>convert_to( source = '0000' ).
  ENDMETHOD.

  METHOD rejects_oversized_payload.
    DATA lv_payload TYPE xstring.
    DATA lv_byte TYPE xstring.

    lv_byte = CONV xstring( 'AA' ).
    DO 65517 TIMES.
      CONCATENATE lv_payload lv_byte INTO lv_payload IN BYTE MODE.
    ENDDO.
    ASSERT zcl_hithub_pkt_line_codec=>encode( lv_payload ) IS INITIAL.
  ENDMETHOD.

  METHOD decodes_binary_packet.
    DATA lv_payload TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    lv_payload = CONV xstring( 'CAFE00FF' ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_packet ).

    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-kind = 'data'.
    ASSERT ls_packet-length = 8.
    ASSERT ls_packet-consumed_bytes = 8.
    ASSERT ls_packet-payload = lv_payload.
  ENDMETHOD.

  METHOD decodes_packet_stream.
    DATA lv_stream TYPE xstring.
    DATA lv_rest TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    lv_stream = zcl_hithub_pkt_line_codec=>encode(
      cl_abap_codepage=>convert_to( source = 'hello' ) ).
    DATA(lv_flush) = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE lv_stream lv_flush INTO lv_stream IN BYTE MODE.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_stream ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to( source = 'hello' ).
    lv_rest = lv_stream+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-kind = 'flush'.
    ASSERT ls_packet-consumed_bytes = 4.
  ENDMETHOD.

  METHOD rejects_malformed_packet.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    ls_packet = zcl_hithub_pkt_line_codec=>decode(
      cl_abap_codepage=>convert_to( source = 'zzzz' ) ).
    ASSERT ls_packet-valid = abap_false.
    ls_packet = zcl_hithub_pkt_line_codec=>decode(
      cl_abap_codepage=>convert_to( source = '0008abc' ) ).
    ASSERT ls_packet-valid = abap_false.
    ls_packet = zcl_hithub_pkt_line_codec=>decode(
      cl_abap_codepage=>convert_to( source = '0003' ) ).
    ASSERT ls_packet-valid = abap_false.
    ls_packet = zcl_hithub_pkt_line_codec=>decode(
      cl_abap_codepage=>convert_to( source = '0001' ) ).
    ASSERT ls_packet-valid = abap_true.
    ASSERT ls_packet-kind = 'delim'.
  ENDMETHOD.

ENDCLASS.
