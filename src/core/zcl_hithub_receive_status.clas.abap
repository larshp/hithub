CLASS zcl_hithub_receive_status DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        ref_name TYPE string,
        ok       TYPE abap_bool,
        reason   TYPE string,
      END OF ty_result,
      ty_results TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY.

    CLASS-METHODS build
      IMPORTING
        iv_unpack_ok TYPE abap_bool
        iv_unpack_error TYPE string OPTIONAL
        it_results TYPE ty_results
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_receive_status IMPLEMENTATION.

  METHOD build.
    DATA lv_line TYPE string.
    DATA lv_text TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA ls_result TYPE ty_result.

    CLEAR rv_response.
    IF iv_unpack_ok = abap_true.
      lv_line = 'unpack ok' && cl_abap_char_utilities=>newline.
    ELSEIF iv_unpack_error IS INITIAL.
      lv_line = 'unpack failed' && cl_abap_char_utilities=>newline.
    ELSE.
      lv_line = |unpack { iv_unpack_error }| &&
        cl_abap_char_utilities=>newline.
    ENDIF.
    lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.

    LOOP AT it_results INTO ls_result.
      IF ls_result-ok = abap_true.
        lv_line = |ok { ls_result-ref_name }| &&
          cl_abap_char_utilities=>newline.
      ELSEIF ls_result-reason IS INITIAL.
        lv_line = |ng { ls_result-ref_name } rejected| &&
          cl_abap_char_utilities=>newline.
      ELSE.
        lv_line = |ng { ls_result-ref_name } { ls_result-reason }| &&
          cl_abap_char_utilities=>newline.
      ENDIF.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ENDLOOP.

    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
