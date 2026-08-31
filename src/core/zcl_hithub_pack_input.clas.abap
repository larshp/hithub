CLASS zcl_hithub_pack_input DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_pack_input.

    METHODS constructor
      IMPORTING
        iv_data TYPE xstring.

  PRIVATE SECTION.
    DATA mv_data TYPE xstring.
    DATA mv_offset TYPE i.

ENDCLASS.

CLASS zcl_hithub_pack_input IMPLEMENTATION.

  METHOD constructor.
    mv_data = iv_data.
    CLEAR mv_offset.
  ENDMETHOD.

  METHOD zif_hithub_pack_input~read.
    DATA lv_remaining TYPE i.
    DATA lv_length TYPE i.

    CLEAR rv_data.
    IF iv_max_bytes <= 0 OR mv_offset >= xstrlen( mv_data ).
      RETURN.
    ENDIF.
    lv_remaining = xstrlen( mv_data ) - mv_offset.
    lv_length = iv_max_bytes.
    IF lv_length > lv_remaining.
      lv_length = lv_remaining.
    ENDIF.
    rv_data = mv_data+mv_offset(lv_length).
    mv_offset = mv_offset + lv_length.
  ENDMETHOD.

  METHOD zif_hithub_pack_input~is_eof.
    rv_eof = boolc( mv_offset >= xstrlen( mv_data ) ).
  ENDMETHOD.

ENDCLASS.
