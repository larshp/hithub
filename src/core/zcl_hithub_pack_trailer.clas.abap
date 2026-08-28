CLASS zcl_hithub_pack_trailer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS is_valid
      IMPORTING
        iv_data TYPE xstring
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_pack_trailer IMPLEMENTATION.

  METHOD is_valid.
    DATA lv_body_length TYPE i.
    DATA lv_body TYPE xstring.
    DATA lv_expected TYPE xstring.
    DATA lv_actual TYPE xstring.

    CLEAR rv_valid.
    IF xstrlen( iv_data ) <= 20.
      RETURN.
    ENDIF.
    lv_body_length = xstrlen( iv_data ) - 20.
    lv_body = iv_data(lv_body_length).
    lv_expected = iv_data+lv_body_length(20).
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING
        if_algorithm = 'sha1'
        if_data = lv_body
      IMPORTING
        ef_hashxstring = lv_actual ).
    IF lv_actual = lv_expected.
      rv_valid = abap_true.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
