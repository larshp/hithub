CLASS zcl_hithub_upload_request DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      BEGIN OF ty_request,
        wants        TYPE ty_lines,
        haves        TYPE ty_lines,
        capabilities TYPE ty_lines,
        deepen       TYPE i,
        saw_flush    TYPE abap_bool,
        saw_done     TYPE abap_bool,
        valid        TYPE abap_bool,
      END OF ty_request.

    CLASS-METHODS parse
      IMPORTING
        iv_data TYPE xstring
      RETURNING
        VALUE(rs_request) TYPE ty_request.

ENDCLASS.

CLASS zcl_hithub_upload_request IMPLEMENTATION.

  METHOD parse.
    DATA lv_remaining TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_command_bytes TYPE xstring.
    DATA lv_capability_bytes TYPE xstring.
    DATA lv_zero TYPE x LENGTH 1.
    DATA lv_offset TYPE i.
    DATA lv_nul_offset TYPE i.
    DATA lv_command TYPE string.
    DATA lv_argument TYPE string.
    DATA lv_line TYPE string.
    DATA lv_capabilities TYPE string.
    DATA lv_last_offset TYPE i.
    DATA lv_deepen TYPE i.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    CLEAR rs_request.
    lv_remaining = iv_data.
    lv_zero = CONV xstring( '00' ).
    WHILE xstrlen( lv_remaining ) > 0.
      ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_remaining ).
      IF ls_packet-valid = abap_false.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      IF ls_packet-kind = 'flush'.
        rs_request-saw_flush = abap_true.
        lv_remaining = lv_remaining+ls_packet-consumed_bytes.
        CONTINUE.
      ENDIF.
      IF ls_packet-kind <> 'data'.
        CLEAR rs_request.
        RETURN.
      ENDIF.

      lv_payload = ls_packet-payload.
      lv_nul_offset = -1.
      lv_offset = 0.
      WHILE lv_offset < xstrlen( lv_payload ).
        IF lv_payload+lv_offset(1) = lv_zero.
          lv_nul_offset = lv_offset.
          EXIT.
        ENDIF.
        lv_offset = lv_offset + 1.
      ENDWHILE.
      IF lv_nul_offset >= 0.
        IF lv_nul_offset = 0.
          CLEAR rs_request.
          RETURN.
        ENDIF.
        lv_command_bytes = lv_payload+0(lv_nul_offset).
        lv_offset = lv_nul_offset + 1.
        IF lv_offset < xstrlen( lv_payload ).
          lv_capability_bytes = lv_payload+lv_offset.
        ENDIF.
      ELSE.
        lv_command_bytes = lv_payload.
        CLEAR lv_capability_bytes.
      ENDIF.

      lv_line = cl_abap_codepage=>convert_from( source = lv_command_bytes ).
      IF lv_line IS INITIAL.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      lv_last_offset = strlen( lv_line ) - 1.
      IF lv_line+lv_last_offset(1) = cl_abap_char_utilities=>newline.
        lv_line = lv_line+0(lv_last_offset).
      ENDIF.
      CLEAR: lv_command, lv_argument.
      SPLIT lv_line AT space INTO lv_command lv_argument.
      CASE lv_command.
        WHEN 'want'.
          IF lv_argument IS INITIAL.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          APPEND lv_argument TO rs_request-wants.
          IF lv_nul_offset >= 0 AND lines( rs_request-wants ) = 1.
            lv_capabilities = cl_abap_codepage=>convert_from(
              source = lv_capability_bytes ).
            IF lv_capabilities IS NOT INITIAL.
              lv_last_offset = strlen( lv_capabilities ) - 1.
              IF lv_capabilities+lv_last_offset(1) = cl_abap_char_utilities=>newline.
                lv_capabilities = lv_capabilities+0(lv_last_offset).
              ENDIF.
              SPLIT lv_capabilities AT space INTO TABLE rs_request-capabilities.
            ENDIF.
          ENDIF.
        WHEN 'have'.
          IF lv_argument IS INITIAL.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          APPEND lv_argument TO rs_request-haves.
        WHEN 'deepen'.
          IF lv_argument IS INITIAL.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          TRY.
              lv_deepen = CONV i( lv_argument ).
            CATCH cx_root.
              CLEAR rs_request.
              RETURN.
          ENDTRY.
          IF lv_deepen < 0.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          rs_request-deepen = lv_deepen.
        WHEN 'done'.
          IF lv_argument IS NOT INITIAL.
            CLEAR rs_request.
            RETURN.
          ENDIF.
          rs_request-saw_done = abap_true.
        WHEN OTHERS.
          CLEAR rs_request.
          RETURN.
      ENDCASE.
      lv_remaining = lv_remaining+ls_packet-consumed_bytes.
    ENDWHILE.

    IF lines( rs_request-wants ) = 0.
      CLEAR rs_request.
      RETURN.
    ENDIF.
    rs_request-valid = abap_true.
  ENDMETHOD.

ENDCLASS.
