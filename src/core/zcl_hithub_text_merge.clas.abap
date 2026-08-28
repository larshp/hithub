CLASS zcl_hithub_text_merge DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        text  TYPE string,
        clean TYPE abap_bool,
      END OF ty_result.

    CLASS-METHODS merge
      IMPORTING
        iv_base   TYPE string
        iv_ours   TYPE string
        iv_theirs TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    TYPES ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLASS-METHODS split
      IMPORTING
        iv_text TYPE string
      RETURNING
        VALUE(rt_lines) TYPE ty_lines.

    CLASS-METHODS join
      IMPORTING
        it_lines TYPE ty_lines
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_hithub_text_merge IMPLEMENTATION.

  METHOD merge.
    DATA lt_base TYPE ty_lines.
    DATA lt_ours TYPE ty_lines.
    DATA lt_theirs TYPE ty_lines.
    DATA lt_result TYPE ty_lines.
    DATA lv_base_line TYPE string.
    DATA lv_ours_line TYPE string.
    DATA lv_theirs_line TYPE string.
    DATA lv_index TYPE i.

    CLEAR rs_result.
    rs_result-clean = abap_true.
    IF iv_ours = iv_theirs.
      rs_result-text = iv_ours.
      RETURN.
    ENDIF.
    IF iv_ours = iv_base.
      rs_result-text = iv_theirs.
      RETURN.
    ENDIF.
    IF iv_theirs = iv_base.
      rs_result-text = iv_ours.
      RETURN.
    ENDIF.

    lt_base = split( iv_text = iv_base ).
    lt_ours = split( iv_text = iv_ours ).
    lt_theirs = split( iv_text = iv_theirs ).
    IF lines( lt_base ) <> lines( lt_ours )
        OR lines( lt_base ) <> lines( lt_theirs ).
      rs_result-clean = abap_false.
      rs_result-text = |<<<<<<< ours{ cl_abap_char_utilities=>newline }|
        && iv_ours && cl_abap_char_utilities=>newline
        && |======={ cl_abap_char_utilities=>newline }|
        && iv_theirs && cl_abap_char_utilities=>newline
        && |>>>>>>> theirs|.
      RETURN.
    ENDIF.

    lv_index = 1.
    WHILE lv_index <= lines( lt_base ).
      READ TABLE lt_base INDEX lv_index INTO lv_base_line.
      READ TABLE lt_ours INDEX lv_index INTO lv_ours_line.
      READ TABLE lt_theirs INDEX lv_index INTO lv_theirs_line.
      IF lv_ours_line = lv_theirs_line.
        APPEND lv_ours_line TO lt_result.
      ELSEIF lv_ours_line = lv_base_line.
        APPEND lv_theirs_line TO lt_result.
      ELSEIF lv_theirs_line = lv_base_line.
        APPEND lv_ours_line TO lt_result.
      ELSE.
        rs_result-clean = abap_false.
        rs_result-text = |<<<<<<< ours{ cl_abap_char_utilities=>newline }|
          && iv_ours && cl_abap_char_utilities=>newline
          && |======={ cl_abap_char_utilities=>newline }|
          && iv_theirs && cl_abap_char_utilities=>newline
          && |>>>>>>> theirs|.
        RETURN.
      ENDIF.
      lv_index = lv_index + 1.
    ENDWHILE.
    rs_result-text = join( it_lines = lt_result ).
  ENDMETHOD.

  METHOD split.
    CLEAR rt_lines.
    SPLIT iv_text AT cl_abap_char_utilities=>newline INTO TABLE rt_lines.
  ENDMETHOD.

  METHOD join.
    DATA lv_line TYPE string.
    CLEAR rv_text.
    LOOP AT it_lines INTO lv_line.
      IF sy-tabix > 1.
        rv_text = rv_text && cl_abap_char_utilities=>newline.
      ENDIF.
      rv_text = rv_text && lv_line.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
