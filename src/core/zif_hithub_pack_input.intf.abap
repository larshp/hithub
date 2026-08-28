INTERFACE zif_hithub_pack_input
  PUBLIC.

  METHODS read
    IMPORTING
      iv_max_bytes TYPE i
    RETURNING
      VALUE(rv_data) TYPE xstring.

  METHODS is_eof
    RETURNING
      VALUE(rv_eof) TYPE abap_bool.

ENDINTERFACE.
