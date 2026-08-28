CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS reads_bounded_chunks FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD reads_bounded_chunks.
    DATA(lo_input) = NEW zcl_hithub_pack_input( CONV xstring( '000102030405' ) ).
    DATA lv_chunk TYPE xstring.

    ASSERT lo_input->zif_hithub_pack_input~is_eof( ) = abap_false.
    lv_chunk = lo_input->zif_hithub_pack_input~read( 2 ).
    ASSERT lv_chunk = CONV xstring( '0001' ).
    lv_chunk = lo_input->zif_hithub_pack_input~read( 3 ).
    ASSERT lv_chunk = CONV xstring( '020304' ).
    lv_chunk = lo_input->zif_hithub_pack_input~read( 8 ).
    ASSERT lv_chunk = CONV xstring( '05' ).
    ASSERT lo_input->zif_hithub_pack_input~is_eof( ) = abap_true.
    ASSERT lo_input->zif_hithub_pack_input~read( 2 ) IS INITIAL.
  ENDMETHOD.

ENDCLASS.
