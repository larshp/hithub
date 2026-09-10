CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS reads_bounded_chunks FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD reads_bounded_chunks.
    DATA(lo_input) = NEW zcl_hithub_pack_input( CONV xstring( '000102030405' ) ).
    DATA lv_chunk TYPE xstring.

    cl_abap_unit_assert=>assert_false(
      act = lo_input->zif_hithub_pack_input~is_eof( ) ).
    lv_chunk = lo_input->zif_hithub_pack_input~read( 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_chunk
      exp = CONV xstring( '0001' ) ).
    lv_chunk = lo_input->zif_hithub_pack_input~read( 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_chunk
      exp = CONV xstring( '020304' ) ).
    lv_chunk = lo_input->zif_hithub_pack_input~read( 8 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_chunk
      exp = CONV xstring( '05' ) ).
    cl_abap_unit_assert=>assert_true(
      act = lo_input->zif_hithub_pack_input~is_eof( ) ).
    cl_abap_unit_assert=>assert_initial(
      act = lo_input->zif_hithub_pack_input~read( 2 ) ).
  ENDMETHOD.

ENDCLASS.
