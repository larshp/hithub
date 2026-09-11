INTERFACE zif_hithub_pack_output
  PUBLIC.

  METHODS write
    IMPORTING
      iv_data TYPE xstring.

  METHODS get_data
    RETURNING
      VALUE(rv_data) TYPE xstring.

ENDINTERFACE.
