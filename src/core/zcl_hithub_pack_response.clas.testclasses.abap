CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS streams_pack_chunks FOR TESTING RAISING cx_static_check.
    METHODS emits_flush_for_empty_pack FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD streams_pack_chunks.
    DATA(lo_output) = NEW zcl_hithub_pack_output( ).
    DATA(lo_response) = NEW zcl_hithub_pack_response( lo_output ).
    DATA lv_pack TYPE xstring.
    DATA lv_expected TYPE xstring.
    DATA lv_byte TYPE xstring.

    lv_byte = CONV xstring( 'AA' ).
    DO 2000 TIMES.
      CONCATENATE lv_pack lv_byte INTO lv_pack IN BYTE MODE.
    ENDDO.
    cl_abap_unit_assert=>assert_equals(
      act = lo_response->stream_pack(
        iv_pack = lv_pack iv_large_band = abap_false )
      exp = 3 ).
    lv_expected = zcl_hithub_sideband_output=>build(
      iv_data = lv_pack iv_large_band = abap_false ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_output->zif_hithub_pack_output~get_data( )
      exp = lv_expected ).
  ENDMETHOD.

  METHOD emits_flush_for_empty_pack.
    DATA(lo_output) = NEW zcl_hithub_pack_output( ).
    DATA(lo_response) = NEW zcl_hithub_pack_response( lo_output ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_response->stream_pack( CONV xstring( '' ) )
      exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_output->zif_hithub_pack_output~get_data( )
      exp = cl_abap_codepage=>convert_to( source = '0000' ) ).
  ENDMETHOD.

ENDCLASS.
