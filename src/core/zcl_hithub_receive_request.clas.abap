CLASS zcl_hithub_receive_request DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      BEGIN OF ty_command,
        old_oid  TYPE string,
        new_oid  TYPE string,
        ref_name TYPE string,
      END OF ty_command,
      ty_commands TYPE STANDARD TABLE OF ty_command WITH DEFAULT KEY,
      BEGIN OF ty_request,
        commands     TYPE ty_commands,
        capabilities TYPE ty_lines,
        pack         TYPE xstring,
        saw_flush    TYPE abap_bool,
        valid        TYPE abap_bool,
      END OF ty_request.

    CLASS-METHODS parse
      IMPORTING
        iv_data           TYPE xstring
      RETURNING
        VALUE(rs_request) TYPE ty_request.

ENDCLASS.

CLASS zcl_hithub_receive_request IMPLEMENTATION.

  METHOD parse.
    DATA lv_remaining TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_zero TYPE xstring.
    DATA lv_line TYPE string.
    DATA lv_last_offset TYPE i.
    DATA lv_nul_offset TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_oid_length TYPE i.
    DATA lv_capabilities TYPE string.
    DATA lv_command_bytes TYPE xstring.
    DATA lv_capability_bytes TYPE xstring.
    DATA lt_fields TYPE ty_lines.
    DATA ls_command TYPE ty_command.
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
        rs_request-pack = lv_remaining+ls_packet-consumed_bytes.
        EXIT.
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
        lv_command_bytes = lv_payload+0(lv_nul_offset).
        lv_line = cl_abap_codepage=>convert_from(
          source = lv_command_bytes ).
        IF lines( rs_request-commands ) > 0.
          CLEAR rs_request.
          RETURN.
        ENDIF.
        lv_offset = lv_nul_offset + 1.
        IF lv_offset < xstrlen( lv_payload ).
          lv_capability_bytes = lv_payload+lv_offset.
          lv_capabilities = cl_abap_codepage=>convert_from(
            source = lv_capability_bytes ).
        ENDIF.
        IF lv_capabilities IS NOT INITIAL.
          lv_last_offset = strlen( lv_capabilities ) - 1.
          IF lv_last_offset >= 0
              AND lv_capabilities+lv_last_offset(1) =
                cl_abap_char_utilities=>newline.
            lv_capabilities = lv_capabilities+0(lv_last_offset).
          ENDIF.
          SPLIT lv_capabilities AT space INTO TABLE rs_request-capabilities.
        ENDIF.
      ELSE.
        lv_line = cl_abap_codepage=>convert_from( source = lv_payload ).
      ENDIF.
      lv_last_offset = strlen( lv_line ) - 1.
      IF lv_last_offset >= 0
          AND lv_line+lv_last_offset(1) = cl_abap_char_utilities=>newline.
        lv_line = lv_line+0(lv_last_offset).
      ENDIF.

      CLEAR lt_fields.
      SPLIT lv_line AT space INTO TABLE lt_fields.
      IF lines( lt_fields ) <> 3.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      CLEAR ls_command.
      ls_command-old_oid = lt_fields[ 1 ].
      ls_command-new_oid = lt_fields[ 2 ].
      ls_command-ref_name = lt_fields[ 3 ].
      IF ( ls_command-old_oid <> '0000000000000000000000000000000000000000'
          AND zcl_hithub_oid_validator=>is_valid(
            iv_algorithm = 'sha1' iv_oid = ls_command-old_oid ) = abap_false )
          OR ( ls_command-new_oid <> '0000000000000000000000000000000000000000'
          AND zcl_hithub_oid_validator=>is_valid(
            iv_algorithm = 'sha1' iv_oid = ls_command-new_oid ) = abap_false )
          OR zcl_hithub_ref_validator=>is_valid( ls_command-ref_name ) = abap_false.
        CLEAR rs_request.
        RETURN.
      ENDIF.
      APPEND ls_command TO rs_request-commands.
      lv_remaining = lv_remaining+ls_packet-consumed_bytes.
    ENDWHILE.

    IF rs_request-saw_flush = abap_false
        OR lines( rs_request-commands ) = 0.
      CLEAR rs_request.
      RETURN.
    ENDIF.
    rs_request-valid = abap_true.
  ENDMETHOD.

ENDCLASS.
