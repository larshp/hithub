INTERFACE zif_hithub_compression
  PUBLIC.

  TYPES:
    BEGIN OF ty_stream_result,
      raw_data       TYPE xstring,
      consumed_bytes TYPE i,
    END OF ty_stream_result.

  METHODS compress
    IMPORTING
      iv_data TYPE xstring
    RETURNING
      VALUE(rv_compressed) TYPE xstring
    RAISING
      cx_static_check.

  METHODS decompress
    IMPORTING
      iv_data TYPE xstring
    RETURNING
      VALUE(rv_decompressed) TYPE xstring
    RAISING
      cx_static_check.

  METHODS decompress_stream
    IMPORTING
      iv_data TYPE xstring
    RETURNING
      VALUE(rs_result) TYPE ty_stream_result
    RAISING
      cx_static_check.

ENDINTERFACE.
