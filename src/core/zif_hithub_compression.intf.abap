INTERFACE zif_hithub_compression
  PUBLIC.

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

ENDINTERFACE.
