CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS validates_pack_checksum FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD validates_pack_checksum.
    DATA lv_pack TYPE xstring.

    lv_pack = CONV xstring(
      '5041434B0000000200000000029D08823BD8A8EAB510AD6AC75C823CFD3ED31E' ).
    ASSERT zcl_hithub_pack_trailer=>is_valid( lv_pack ) = abap_true.

    lv_pack = CONV xstring(
      '5041434B0000000200000000029D08823BD8A8EAB510AD6AC75C823CFD3ED31F' ).
    ASSERT zcl_hithub_pack_trailer=>is_valid( lv_pack ) = abap_false.
    ASSERT zcl_hithub_pack_trailer=>is_valid( CONV xstring( '000102' ) ) = abap_false.
  ENDMETHOD.

ENDCLASS.
