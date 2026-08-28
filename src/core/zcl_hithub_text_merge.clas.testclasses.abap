CLASS ltcl_text_merge DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS merges_independent_lines FOR TESTING RAISING cx_static_check.
    METHODS reports_text_conflict FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_text_merge IMPLEMENTATION.

  METHOD merges_independent_lines.
    DATA ls_result TYPE zcl_hithub_text_merge=>ty_result.
    DATA lv_newline TYPE string.
    lv_newline = cl_abap_char_utilities=>newline.

    ls_result = zcl_hithub_text_merge=>merge(
      iv_base = |a{ lv_newline }b{ lv_newline }c|
      iv_ours = |A{ lv_newline }b{ lv_newline }c|
      iv_theirs = |a{ lv_newline }b{ lv_newline }C| ).
    ASSERT ls_result-clean = abap_true.
    ASSERT ls_result-text = |A{ lv_newline }b{ lv_newline }C|.
  ENDMETHOD.

  METHOD reports_text_conflict.
    DATA ls_result TYPE zcl_hithub_text_merge=>ty_result.
    ls_result = zcl_hithub_text_merge=>merge(
      iv_base = 'base' iv_ours = 'ours' iv_theirs = 'theirs' ).

    ASSERT ls_result-clean = abap_false.
    ASSERT ls_result-text CS '<<<<<<< ours'.
    ASSERT ls_result-text CS '======='. 
    ASSERT ls_result-text CS '>>>>>>> theirs'.
  ENDMETHOD.

ENDCLASS.
