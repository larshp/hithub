CLASS zcl_hithub_upload_negotiation DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS build
      IMPORTING
        is_request         TYPE zcl_hithub_upload_request=>ty_request
        it_common          TYPE zcl_hithub_upload_request=>ty_lines
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_upload_negotiation IMPLEMENTATION.

  METHOD build.
    DATA lv_oid TYPE string.
    DATA lv_line TYPE string.
    DATA lv_text TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA lv_ack_mode TYPE string.
    DATA lv_common_found TYPE abap_bool.
    DATA lv_seen TYPE abap_bool.
    DATA lt_acked TYPE zcl_hithub_upload_request=>ty_lines.

    CLEAR rv_response.
    READ TABLE is_request-capabilities WITH KEY table_line = 'multi_ack_detailed'
      TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      lv_ack_mode = 'detailed'.
    ELSE.
      READ TABLE is_request-capabilities WITH KEY table_line = 'multi_ack'
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lv_ack_mode = 'continue'.
      ENDIF.
    ENDIF.

    LOOP AT is_request-haves INTO lv_oid.
      READ TABLE it_common WITH KEY table_line = lv_oid
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      READ TABLE lt_acked WITH KEY table_line = lv_oid
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      APPEND lv_oid TO lt_acked.
      lv_common_found = abap_true.
      IF lv_ack_mode = 'detailed'.
        lv_line = |ACK { lv_oid } common| && cl_abap_char_utilities=>newline.
      ELSEIF lv_ack_mode = 'continue'.
        lv_line = |ACK { lv_oid } continue| && cl_abap_char_utilities=>newline.
      ELSE.
        lv_line = |ACK { lv_oid }| && cl_abap_char_utilities=>newline.
      ENDIF.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ENDLOOP.

    IF lv_common_found = abap_false.
      lv_text = cl_abap_codepage=>convert_to(
        source = 'NAK' && cl_abap_char_utilities=>newline ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
