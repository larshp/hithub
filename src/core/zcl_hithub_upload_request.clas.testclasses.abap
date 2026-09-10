CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_v0_request FOR TESTING RAISING cx_static_check.
    METHODS parses_space_capabilities FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_request FOR TESTING RAISING cx_static_check.
    METHODS finds_the_blank_separator FOR TESTING RAISING cx_static_check.

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
    cl_abap_unit_assert=>assert_true( act = ls_request-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_request-wants )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_request-haves )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_request-deepen exp = 5 ).
    cl_abap_unit_assert=>assert_true( act = ls_request-saw_flush ).
    cl_abap_unit_assert=>assert_true( act = ls_request-saw_done ).
    READ TABLE ls_request-capabilities WITH KEY table_line = 'side-band-64k'
      TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).
  ENDMETHOD.

  METHOD parses_space_capabilities.
    DATA lv_oid TYPE string.
    DATA lv_payload TYPE xstring.
    DATA lv_data TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.

    lv_oid = '1111111111111111111111111111111111111111'.
    lv_payload = cl_abap_codepage=>convert_to(
      source = |want { lv_oid } no-progress agent=git/2.43.0| &&
        cl_abap_char_utilities=>newline ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_payload ).
    CONCATENATE lv_data lv_packet INTO lv_data IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE lv_data lv_packet
      INTO lv_data IN BYTE MODE.

    ls_request = zcl_hithub_upload_request=>parse( lv_data ).
    cl_abap_unit_assert=>assert_true( act = ls_request-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_request-wants )
      exp = 1 ).
    " A want that carries its capabilities behind a blank instead of a NUL
    " has to be cut back to the bare oid.
    cl_abap_unit_assert=>assert_equals(
      act = strlen( ls_request-wants[ 1 ] )
      exp = 40
      msg = 'the capability list was not split off the want line' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_request-capabilities )
      exp = 2
      msg = 'the blank separated capabilities were not collected' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_request-wants[ 1 ]
      exp = lv_oid ).
    READ TABLE ls_request-capabilities WITH KEY table_line = 'no-progress'
      TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).
    READ TABLE ls_request-capabilities WITH KEY table_line = 'agent=git/2.43.0'
      TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).
  ENDMETHOD.

  METHOD rejects_bad_request.
    DATA lv_packet TYPE xstring.
    DATA ls_request TYPE zcl_hithub_upload_request=>ty_request.

    lv_packet = zcl_hithub_pkt_line_codec=>encode(
      cl_abap_codepage=>convert_to( source = 'wat' &&
        cl_abap_char_utilities=>newline ) ).
    ls_request = zcl_hithub_upload_request=>parse( lv_packet ).
    cl_abap_unit_assert=>assert_false( act = ls_request-valid ).
    ls_request = zcl_hithub_upload_request=>parse(
      cl_abap_codepage=>convert_to( source = '0008abc' ) ).
    cl_abap_unit_assert=>assert_false( act = ls_request-valid ).
  ENDMETHOD.

  METHOD finds_the_blank_separator.
    " parse( ) locates the capability list with FIND ... OF space and cuts
    " the want line with SPLIT ... AT space. Trailing blanks are ignored in
    " flat character operands, so the two statements need not agree on what
    " a single blank means.
    DATA lv_line TYPE string.
    DATA lv_literal_offset TYPE i.
    DATA lv_space_offset TYPE i.
    DATA lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    lv_line = |want 1111111111111111111111111111111111111111 no-progress|.

    FIND FIRST OCCURRENCE OF ` ` IN lv_line MATCH OFFSET lv_literal_offset.
    cl_abap_unit_assert=>assert_subrc(
      msg = 'a blank text string literal matches nothing' ).
    cl_abap_unit_assert=>assert_equals( act = lv_literal_offset exp = 4 ).

    FIND FIRST OCCURRENCE OF space IN lv_line MATCH OFFSET lv_space_offset.
    cl_abap_unit_assert=>assert_subrc(
      msg = 'FIND FIRST OCCURRENCE OF space matches nothing' ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_space_offset
      exp = 4
      msg = 'FIND ... OF space does not match a single blank' ).

    SPLIT lv_line AT space INTO TABLE lt_parts.
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_parts )
      exp = 3
      msg = 'SPLIT ... AT space does not split at single blanks' ).
  ENDMETHOD.

ENDCLASS.
