CLASS zcl_hithub_ref_delta DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS decode
      IMPORTING
        iv_data          TYPE xstring
        iv_base          TYPE xstring
      RETURNING
        VALUE(rv_result) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_ref_delta IMPLEMENTATION.

  METHOD decode.
    DATA ls_entry TYPE zcl_hithub_pack_entry=>ty_entry.
    DATA lv_delta TYPE xstring.

    CLEAR rv_result.
    ls_entry = zcl_hithub_pack_entry=>parse( iv_data ).
    IF ls_entry-type <> 'ref-delta'
        OR ls_entry-base_oid IS INITIAL.
      RETURN.
    ENDIF.
    lv_delta = iv_data+ls_entry-data_offset.
    rv_result = zcl_hithub_delta_codec=>apply(
      iv_base = iv_base iv_delta = lv_delta ).
  ENDMETHOD.

ENDCLASS.
