CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trips_raw_deflate FOR TESTING RAISING cx_static_check.
    METHODS reads_abapgit_pack_corpus FOR TESTING RAISING cx_static_check.

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

  METHOD reads_abapgit_pack_corpus.
    DATA(lo_compression) = NEW zcl_hithub_abap_compression( ).
    DATA lv_pack TYPE xstring.
    DATA lv_body_length TYPE i.
    DATA lv_body TYPE xstring.
    DATA lv_entry TYPE xstring.
    DATA lv_compressed TYPE xstring.
    DATA lv_expected_raw TYPE xstring.
    DATA lv_header TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_digest TYPE xstring.
    DATA ls_stream TYPE zif_hithub_compression=>ty_stream_result.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.

    lv_pack = CONV xstring(
      '5041434B000000020000000136789C4BCAC94F523063C848CDC9C9E702001DC50414C32ABA73BDEEF306ABCA597B61B1FE3E349320E4' ).
    lv_body_length = xstrlen( lv_pack ) - 20.
    lv_body = lv_pack+0(lv_body_length).
    lv_entry = lv_body+12.
    lv_compressed = lv_entry+1.
    lv_payload = cl_abap_codepage=>convert_to(
      source = |hello{ cl_abap_char_utilities=>newline }| ).
    lv_header = zcl_hithub_object_header=>generate(
      iv_type = 'blob' iv_size = xstrlen( lv_payload ) ).
    CONCATENATE lv_header lv_payload INTO lv_expected_raw IN BYTE MODE.

    ls_header = zcl_hithub_pack_header=>parse( lv_pack ).
    ASSERT ls_header-signature = 'PACK'.
    ASSERT ls_header-version = 2.
    ASSERT ls_header-object_count = 1.
    ASSERT zcl_hithub_pack_trailer=>is_valid( lv_pack ) = abap_true.

    ls_stream = lo_compression->zif_hithub_compression~decompress_stream(
      lv_compressed ).
    ASSERT ls_stream-raw_data = lv_expected_raw.
    ASSERT ls_stream-consumed_bytes = xstrlen( lv_compressed ).

    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING
        if_algorithm = 'sha1'
        if_data = lv_expected_raw
      IMPORTING
        ef_hashxstring = lv_digest ).
    ASSERT lv_digest = CONV xstring(
      'CE013625030BA8DBA906F756967F9E9CA394464A' ).
    ASSERT zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ) =
      'ce013625030ba8dba906f756967f9e9ca394464a'.
  ENDMETHOD.

ENDCLASS.
