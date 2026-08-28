CLASS zcl_hithub_ofs_delta DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS decode
      IMPORTING
        iv_data            TYPE xstring
        iv_current_offset  TYPE i
        iv_base            TYPE xstring
      RETURNING
        VALUE(rv_result) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_ofs_delta IMPLEMENTATION.

  METHOD decode.
    DATA ls_entry TYPE zcl_hithub_pack_entry=>ty_entry.
    DATA lv_delta TYPE xstring.

    CLEAR rv_result.
    ls_entry = zcl_hithub_pack_entry=>parse( iv_data ).
    IF ls_entry-type <> 'ofs-delta'
        OR ls_entry-base_distance <= 0
        OR iv_current_offset <= ls_entry-base_distance.
      RETURN.
    ENDIF.
    lv_delta = iv_data+ls_entry-data_offset.
    rv_result = zcl_hithub_delta_codec=>apply(
      iv_base = iv_base iv_delta = lv_delta ).
  ENDMETHOD.

ENDCLASS.
