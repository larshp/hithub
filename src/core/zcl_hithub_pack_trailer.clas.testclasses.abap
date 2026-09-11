CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS validates_pack_checksum FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD validates_pack_checksum.
    DATA lv_pack TYPE xstring.

    lv_pack = CONV xstring(
      '5041434B0000000200000000029D08823BD8A8EAB510AD6AC75C823CFD3ED31E' ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pack_trailer=>is_valid( lv_pack ) ).

    lv_pack = CONV xstring(
      '5041434B0000000200000000029D08823BD8A8EAB510AD6AC75C823CFD3ED31F' ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pack_trailer=>is_valid( lv_pack ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pack_trailer=>is_valid( CONV xstring( '000102' ) ) ).
  ENDMETHOD.

ENDCLASS.
