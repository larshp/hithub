CLASS lcl_compression DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_compression.

ENDCLASS.

CLASS lcl_compression IMPLEMENTATION.

  METHOD zif_hithub_compression~compress.
    DATA lv_marker TYPE xstring.

    lv_marker = CONV xstring( 'CAFE' ).
    CONCATENATE lv_marker iv_data INTO rv_compressed IN BYTE MODE.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress.
    rv_decompressed = iv_data+2.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress_stream.
    rs_result-raw_data = iv_data.
    rs_result-consumed_bytes = xstrlen( iv_data ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS compresses_object_bytes FOR TESTING RAISING cx_static_check.
    METHODS decompresses_object_bytes FOR TESTING RAISING cx_static_check.
    METHODS rejects_malformed_objects FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD compresses_object_bytes.
    DATA lo_compression TYPE REF TO lcl_compression.
    DATA lo_codec TYPE REF TO zcl_hithub_loose_object_codec.
    DATA lv_data TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_expected TYPE xstring.

    lo_compression = NEW lcl_compression( ).
    lo_codec = NEW zcl_hithub_loose_object_codec( lo_compression ).
    lv_payload = cl_abap_codepage=>convert_to( source = 'hello' ).
    lv_data = lo_codec->compress(
      iv_type = 'blob' iv_payload = lv_payload ).
    lv_expected = CONV xstring( 'CAFE626C6F6220350068656C6C6F' ).

    ASSERT lv_data = lv_expected.
  ENDMETHOD.

  METHOD decompresses_object_bytes.
    DATA lo_compression TYPE REF TO lcl_compression.
    DATA lo_codec TYPE REF TO zcl_hithub_loose_object_codec.
    DATA ls_object TYPE zcl_hithub_loose_object_codec=>ty_object.
    DATA lv_raw TYPE xstring.
    DATA lv_header TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_compressed TYPE xstring.
    DATA lv_marker TYPE xstring.

    lo_compression = NEW lcl_compression( ).
    lo_codec = NEW zcl_hithub_loose_object_codec( lo_compression ).
    lv_header = zcl_hithub_object_header=>generate(
      iv_type = 'blob' iv_size = 5 ).
    lv_payload = cl_abap_codepage=>convert_to( source = 'hello' ).
    CONCATENATE lv_header lv_payload INTO lv_raw IN BYTE MODE.
    lv_marker = CONV xstring( 'CAFE' ).
    CONCATENATE lv_marker lv_raw INTO lv_compressed IN BYTE MODE.

    ls_object = lo_codec->decompress( lv_compressed ).

    ASSERT ls_object-type = 'blob'.
    ASSERT ls_object-size = 5.
    ASSERT ls_object-payload = lv_payload.
    ls_object = lo_codec->decompress(
      iv_data = lv_compressed iv_max_size = 4 ).
    ASSERT ls_object-type IS INITIAL.
  ENDMETHOD.

  METHOD rejects_malformed_objects.
    DATA lo_compression TYPE REF TO lcl_compression.
    DATA lo_codec TYPE REF TO zcl_hithub_loose_object_codec.
    DATA ls_object TYPE zcl_hithub_loose_object_codec=>ty_object.
    DATA lv_marker TYPE xstring.
    DATA lv_raw TYPE xstring.
    DATA lv_compressed TYPE xstring.
    DATA lv_prefix TYPE xstring.
    DATA lv_payload TYPE xstring.
    DATA lv_zero TYPE x LENGTH 1.

    lo_compression = NEW lcl_compression( ).
    lo_codec = NEW zcl_hithub_loose_object_codec( lo_compression ).
    lv_marker = CONV xstring( 'CAFE' ).

    lv_raw = cl_abap_codepage=>convert_to( source = 'blob 1' ).
    CONCATENATE lv_marker lv_raw INTO lv_compressed IN BYTE MODE.
    ls_object = lo_codec->decompress( lv_compressed ).
    ASSERT ls_object-type IS INITIAL.

    lv_prefix = cl_abap_codepage=>convert_to( source = 'blob x' ).
    CONCATENATE lv_prefix lv_zero INTO lv_raw IN BYTE MODE.
    CONCATENATE lv_marker lv_raw INTO lv_compressed IN BYTE MODE.
    ls_object = lo_codec->decompress( lv_compressed ).
    ASSERT ls_object-type IS INITIAL.

    lv_prefix = cl_abap_codepage=>convert_to( source = 'blob 2' ).
    lv_payload = cl_abap_codepage=>convert_to( source = 'x' ).
    CONCATENATE lv_prefix lv_zero lv_payload INTO lv_raw IN BYTE MODE.
    CONCATENATE lv_marker lv_raw INTO lv_compressed IN BYTE MODE.
    ls_object = lo_codec->decompress( lv_compressed ).
    ASSERT ls_object-type IS INITIAL.
  ENDMETHOD.

ENDCLASS.
