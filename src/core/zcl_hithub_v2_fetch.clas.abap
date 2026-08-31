CLASS zcl_hithub_v2_fetch DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      BEGIN OF ty_request,
        wants    TYPE ty_lines,
        haves    TYPE ty_lines,
        features TYPE ty_lines,
        saw_done TYPE abap_bool,
        valid    TYPE abap_bool,
      END OF ty_request.

    CLASS-METHODS parse
      IMPORTING
        iv_data           TYPE xstring
      RETURNING
        VALUE(rs_request) TYPE ty_request.

    CLASS-METHODS build_response
      IMPORTING
        iv_pack            TYPE xstring
      RETURNING
        VALUE(rv_response) TYPE xstring.

    CLASS-METHODS build_acknowledgments
      IMPORTING
        it_common_haves    TYPE ty_lines
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_v2_fetch IMPLEMENTATION.

  METHOD parse.
    DATA lv_remaining TYPE xstring.
    DATA lv_line TYPE string.
    DATA lv_command TYPE string.
    DATA lv_argument TYPE string.
    DATA lv_last_offset TYPE i.
    DATA lv_first TYPE abap_bool.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    CLEAR rs_request.
    lv_remaining = iv_data.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_remaining ).
    IF ls_packet-valid = abap_false OR ls_packet-kind <> 'data'.
      RETURN.
    ENDIF.
    lv_line = cl_abap_codepage=>convert_from( source = ls_packet-payload ).
    lv_last_offset = strlen( lv_line ) - 1.
    IF lv_last_offset >= 0 AND lv_line+lv_last_offset(1) = cl_abap_char_utilities=>newline.
      lv_line = lv_line+0(lv_last_offset).
    ENDIF.
    IF lv_line IS INITIAL.
      RETURN.
    ENDIF.
    IF lv_line <> 'command=fetch'.
      RETURN.
    ENDIF.
    lv_remaining = lv_remaining+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_remaining ).
    IF ls_packet-valid = abap_false.
      RETURN.
    ENDIF.
    IF ls_packet-kind = 'data'.
      lv_line = cl_abap_codepage=>convert_from( source = ls_packet-payload ).
      lv_last_offset = strlen( lv_line ) - 1.
      IF lv_last_offset >= 0 AND lv_line+lv_last_offset(1) = cl_abap_char_utilities=>newline.
        lv_line = lv_line+0(lv_last_offset).
      ENDIF.
      IF lv_line IS INITIAL.
        RETURN.
      ENDIF.
      IF lv_line NP 'agent=*'.
        RETURN.
      ENDIF.
      lv_remaining = lv_remaining+ls_packet-consumed_bytes.
      ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_remaining ).
      IF ls_packet-valid = abap_false.
        RETURN.
      ENDIF.
    ENDIF.
    IF ls_packet-kind <> 'delim'.
      RETURN.
    ENDIF.
    lv_remaining = lv_remaining+ls_packet-consumed_bytes.
    lv_first = abap_true.

    WHILE xstrlen( lv_remaining ) > 0.
      ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_remaining ).
      IF ls_packet-valid = abap_false.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      IF ls_packet-kind = 'flush'.
        lv_remaining = lv_remaining+ls_packet-consumed_bytes.
        EXIT.
      ENDIF.
      IF ls_packet-kind <> 'data'.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      lv_line = cl_abap_codepage=>convert_from( source = ls_packet-payload ).
      lv_last_offset = strlen( lv_line ) - 1.
      IF lv_last_offset >= 0 AND lv_line+lv_last_offset(1) = cl_abap_char_utilities=>newline.
        lv_line = lv_line+0(lv_last_offset).
      ENDIF.
      IF lv_line IS INITIAL.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      CLEAR: lv_command, lv_argument.
      SPLIT lv_line AT space INTO lv_command lv_argument.
      CASE lv_command.
        WHEN 'want'.
          IF zcl_hithub_oid_validator=>is_valid(
              iv_algorithm = 'sha1' iv_oid = lv_argument ) = abap_false.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          APPEND lv_argument TO rs_request-wants.
        WHEN 'have'.
          IF zcl_hithub_oid_validator=>is_valid(
              iv_algorithm = 'sha1' iv_oid = lv_argument ) = abap_false.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          APPEND lv_argument TO rs_request-haves.
        WHEN 'done'.
          IF lv_argument IS NOT INITIAL.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          rs_request-saw_done = abap_true.
        WHEN 'thin-pack' OR 'ofs-delta' OR 'include-tag' OR 'no-progress'.
          IF lv_argument IS NOT INITIAL.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          APPEND lv_command TO rs_request-features.
        WHEN OTHERS.
          CLEAR rs_request.
          RETURN.
      ENDCASE.
      lv_remaining = lv_remaining+ls_packet-consumed_bytes.
      lv_first = abap_false.
    ENDWHILE.

    IF lines( rs_request-wants ) = 0.
      CLEAR rs_request.
      RETURN.
    ENDIF.
    rs_request-valid = abap_true.
  ENDMETHOD.

  METHOD build_response.
    DATA lv_text TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA lv_sideband TYPE xstring.

    CLEAR rv_response.
    IF iv_pack IS INITIAL.
      RETURN.
    ENDIF.
    lv_text = cl_abap_codepage=>convert_to( source = 'packfile' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    lv_sideband = zcl_hithub_sideband_output=>build( iv_pack ).
    CONCATENATE lv_packet lv_sideband INTO rv_response IN BYTE MODE.
  ENDMETHOD.

  METHOD build_acknowledgments.
    DATA lv_text TYPE xstring.
    DATA lv_line TYPE string.
    DATA lv_packet TYPE xstring.
    DATA lv_oid TYPE string.

    CLEAR rv_response.
    lv_text = cl_abap_codepage=>convert_to( source = 'acknowledgments' &&
      cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    IF it_common_haves IS INITIAL.
      lv_line = 'NAK' && cl_abap_char_utilities=>newline.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ELSE.
      LOOP AT it_common_haves INTO lv_oid.
        lv_line = |ACK { lv_oid }| && cl_abap_char_utilities=>newline.
        lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
        lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
        CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
      ENDLOOP.
      lv_line = 'ready' && cl_abap_char_utilities=>newline.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ENDIF.
    lv_packet = cl_abap_codepage=>convert_to( source = '0001' ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
