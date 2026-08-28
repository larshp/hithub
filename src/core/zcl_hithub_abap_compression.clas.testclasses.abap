CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trips_raw_deflate FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD round_trips_raw_deflate.
    DATA(lo_compression) = NEW zcl_hithub_abap_compression( ).
    DATA lv_raw TYPE xstring.
    DATA lv_compressed TYPE xstring.
    DATA lv_roundtrip TYPE xstring.
    DATA ls_stream TYPE zif_hithub_compression=>ty_stream_result.

    lv_raw = cl_abap_codepage=>convert_to( source = 'compression adapter' ).
    lv_compressed = lo_compression->zif_hithub_compression~compress( lv_raw ).
    ASSERT lv_compressed IS NOT INITIAL.
    ASSERT lv_compressed+0(2) = CONV xstring( '789C' ).
    lv_roundtrip = lo_compression->zif_hithub_compression~decompress(
      lv_compressed ).
    ASSERT lv_roundtrip = lv_raw.
    ls_stream = lo_compression->zif_hithub_compression~decompress_stream(
      lv_compressed ).
    ASSERT ls_stream-raw_data = lv_raw.
    ASSERT ls_stream-consumed_bytes = xstrlen( lv_compressed ).
  ENDMETHOD.

ENDCLASS.
