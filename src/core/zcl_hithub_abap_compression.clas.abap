CLASS zcl_hithub_abap_compression DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_compression.

ENDCLASS.

CLASS zcl_hithub_abap_compression IMPLEMENTATION.

  METHOD zif_hithub_compression~compress.
    DATA lv_length TYPE i.

    CLEAR rv_compressed.
    cl_abap_gzip=>compress_binary(
      EXPORTING
        raw_in = iv_data
      IMPORTING
        gzip_out = rv_compressed
        gzip_out_len = lv_length ).
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress.
    DATA lv_length TYPE i.

    CLEAR rv_decompressed.
    cl_abap_gzip=>decompress_binary(
      EXPORTING
        gzip_in = iv_data
      IMPORTING
        raw_out = rv_decompressed
        raw_out_len = lv_length ).
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress_stream.
    DATA lv_length TYPE i.

    CLEAR rs_result.
    cl_abap_gzip=>decompress_binary(
      EXPORTING
        gzip_in = iv_data
      IMPORTING
        raw_out = rs_result-raw_data
        raw_out_len = lv_length ).
    rs_result-consumed_bytes = xstrlen( iv_data ).
  ENDMETHOD.

ENDCLASS.
