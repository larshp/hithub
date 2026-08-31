CLASS zcl_hithub_protocol_v2 DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS advertise
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_protocol_v2 IMPLEMENTATION.

  METHOD advertise.
    DATA lv_text TYPE xstring.
    DATA lv_packet TYPE xstring.

    CLEAR rv_response.
    lv_text = cl_abap_codepage=>convert_to( source = 'version 2' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    lv_text = cl_abap_codepage=>convert_to( source = 'agent=hithub' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    lv_text = cl_abap_codepage=>convert_to( source = 'ls-refs' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    lv_text = cl_abap_codepage=>convert_to( source = 'fetch=shallow' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
