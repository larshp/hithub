CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS writes_stream_chunks FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD writes_stream_chunks.
    DATA(lo_output) = NEW zcl_hithub_pack_output( ).

    lo_output->zif_hithub_pack_output~write( CONV xstring( '0001' ) ).
    lo_output->zif_hithub_pack_output~write( CONV xstring( '020304' ) ).
    lo_output->zif_hithub_pack_output~write( CONV xstring( '05' ) ).
    lo_output->zif_hithub_pack_output~write( CONV xstring( '' ) ).

    ASSERT lo_output->zif_hithub_pack_output~get_data( ) =
      CONV xstring( '000102030405' ).
  ENDMETHOD.

ENDCLASS.
