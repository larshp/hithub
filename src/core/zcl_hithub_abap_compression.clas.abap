CLASS zcl_hithub_abap_compression DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_compression.

ENDCLASS.

CLASS zcl_hithub_abap_compression IMPLEMENTATION.

  METHOD zif_hithub_compression~compress.
    DATA lv_raw_compressed TYPE xstring.
    DATA lv_header TYPE xstring.
    DATA lv_checksum TYPE xstring.
    DATA lv_length TYPE i.

    CLEAR rv_compressed.
    cl_abap_gzip=>compress_binary(
      EXPORTING
        raw_in       = iv_data
      IMPORTING
        gzip_out     = lv_raw_compressed
        gzip_out_len = lv_length ).
    lv_header = CONV xstring( '789C' ).
    lv_checksum = zcl_hithub_adler32=>calculate( iv_data ).
    CONCATENATE lv_header lv_raw_compressed
      INTO rv_compressed IN BYTE MODE.
    CONCATENATE rv_compressed lv_checksum
      INTO rv_compressed IN BYTE MODE.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress.
    DATA lv_raw_compressed TYPE xstring.
    DATA lv_length TYPE i.

    CLEAR rv_decompressed.
    IF xstrlen( iv_data ) < 6.
      RETURN.
    ENDIF.
    lv_raw_compressed = iv_data+2.
    cl_abap_gzip=>decompress_binary(
      EXPORTING
        gzip_in     = lv_raw_compressed
      IMPORTING
        raw_out     = rv_decompressed
        raw_out_len = lv_length ).
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress_stream.
    DATA lv_raw_compressed TYPE xstring.
    DATA lv_compressed TYPE xstring.
    DATA lv_compressed_length TYPE i.
    DATA lv_data_length TYPE i.
    DATA lv_input_prefix TYPE xstring.
    DATA lv_length TYPE i.
    DATA lv_candidate_length TYPE i.
    DATA lv_deflate_length TYPE i.
    DATA lv_candidate_data TYPE xstring.
    DATA lv_checksum TYPE xstring.
    DATA lv_checksum_offset TYPE i.
    DATA lv_adler TYPE xstring.

    CLEAR rs_result.
    IF xstrlen( iv_data ) < 6.
      RETURN.
    ENDIF.
    lv_raw_compressed = iv_data+2.
    TRY.
        cl_abap_gzip=>decompress_binary(
          EXPORTING
            gzip_in     = lv_raw_compressed
          IMPORTING
            raw_out     = rs_result-raw_data
            raw_out_len = lv_length ).
        cl_abap_gzip=>compress_binary(
          EXPORTING
            raw_in       = rs_result-raw_data
          IMPORTING
            gzip_out     = lv_compressed
            gzip_out_len = lv_length ).
      CATCH cx_root.
        CLEAR rs_result-raw_data.
        CLEAR lv_compressed.
    ENDTRY.
    lv_compressed_length = xstrlen( lv_compressed ).
    lv_data_length = xstrlen( iv_data ).
    IF lv_data_length >= lv_compressed_length + 6.
      lv_input_prefix = iv_data+2(lv_compressed_length).
    ENDIF.
    IF lv_data_length >= lv_compressed_length + 6
        AND lv_input_prefix = lv_compressed.
      rs_result-consumed_bytes = lv_compressed_length + 6.
      RETURN.
    ENDIF.

    " Git clients may use a different valid deflate stream than the local
    " compressor. Find the first complete zlib member by checking Adler-32.
    CLEAR rs_result.
    lv_candidate_length = 7.
    WHILE lv_candidate_length <= xstrlen( iv_data ).
      lv_deflate_length = lv_candidate_length - 6.
      lv_candidate_data = iv_data+2(lv_deflate_length).
      CLEAR rs_result-raw_data.
      TRY.
          cl_abap_gzip=>decompress_binary(
            EXPORTING
              gzip_in     = lv_candidate_data
            IMPORTING
              raw_out     = rs_result-raw_data
              raw_out_len = lv_length ).
        CATCH cx_root.
          CLEAR rs_result-raw_data.
      ENDTRY.
      IF rs_result-raw_data IS NOT INITIAL.
        lv_adler = zcl_hithub_adler32=>calculate( rs_result-raw_data ).
      ELSE.
        lv_adler = zcl_hithub_adler32=>calculate( CONV xstring( '' ) ).
      ENDIF.
      lv_checksum_offset = lv_candidate_length - 4.
      lv_checksum = iv_data+lv_checksum_offset(4).
      IF lv_adler = lv_checksum.
        rs_result-consumed_bytes = lv_candidate_length.
        RETURN.
      ENDIF.
      lv_candidate_length = lv_candidate_length + 1.
    ENDWHILE.
    CLEAR rs_result.
  ENDMETHOD.

ENDCLASS.
