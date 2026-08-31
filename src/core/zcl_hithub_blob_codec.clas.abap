CLASS zcl_hithub_blob_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS encode
      IMPORTING
        iv_payload        TYPE xstring
      RETURNING
        VALUE(rv_payload) TYPE xstring.

    CLASS-METHODS decode
      IMPORTING
        iv_payload        TYPE xstring
      RETURNING
        VALUE(rv_payload) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_blob_codec IMPLEMENTATION.

  METHOD encode.
    rv_payload = iv_payload.
  ENDMETHOD.

  METHOD decode.
    rv_payload = iv_payload.
  ENDMETHOD.

ENDCLASS.
