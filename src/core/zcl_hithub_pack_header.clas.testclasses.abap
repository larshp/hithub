CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_pack_header FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_header FOR TESTING RAISING cx_static_check.
    METHODS builds_pack_header FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_pack_header.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.

    ls_header = zcl_hithub_pack_header=>parse(
      CONV xstring( '5041434B0000000200000003' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_header-signature
      exp = 'PACK' ).
    cl_abap_unit_assert=>assert_equals( act = ls_header-version exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_header-object_count exp = 3 ).
  ENDMETHOD.

  METHOD rejects_invalid_header.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.

    ls_header = zcl_hithub_pack_header=>parse( CONV xstring( '5041434B' ) ).
    cl_abap_unit_assert=>assert_initial( act = ls_header-signature ).
    ls_header = zcl_hithub_pack_header=>parse(
      CONV xstring( '504143580000000200000003' ) ).
    cl_abap_unit_assert=>assert_initial( act = ls_header-signature ).
    ls_header = zcl_hithub_pack_header=>parse(
      CONV xstring( '5041434B0000000100000003' ) ).
    cl_abap_unit_assert=>assert_initial( act = ls_header-signature ).
  ENDMETHOD.

  METHOD builds_pack_header.
    DATA lv_data TYPE xstring.

    lv_data = zcl_hithub_pack_header=>build( 3 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_data
      exp = CONV xstring( '5041434B0000000200000003' ) ).
  ENDMETHOD.

ENDCLASS.
