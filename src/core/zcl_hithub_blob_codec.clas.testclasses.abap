CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS preserves_binary_payload FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD preserves_binary_payload.
    DATA lv_payload TYPE xstring.
    DATA lv_encoded TYPE xstring.
    DATA lv_decoded TYPE xstring.

    lv_payload = CONV xstring( 'blob fixture' ).
    lv_encoded = zcl_hithub_blob_codec=>encode( lv_payload ).
    lv_decoded = zcl_hithub_blob_codec=>decode( lv_encoded ).

    ASSERT lv_encoded = lv_payload.
    ASSERT lv_decoded = lv_payload.
  ENDMETHOD.

ENDCLASS.
