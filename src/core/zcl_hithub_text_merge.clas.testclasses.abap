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
      iv_base   = |a{ lv_newline }b{ lv_newline }c|
      iv_ours   = |A{ lv_newline }b{ lv_newline }c|
      iv_theirs = |a{ lv_newline }b{ lv_newline }C| ).
    cl_abap_unit_assert=>assert_true( act = ls_result-clean ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-text
      exp = |A{ lv_newline }b{ lv_newline }C| ).
  ENDMETHOD.

  METHOD reports_text_conflict.
    DATA ls_result TYPE zcl_hithub_text_merge=>ty_result.
    ls_result = zcl_hithub_text_merge=>merge(
      iv_base = 'base' iv_ours = 'ours' iv_theirs = 'theirs' ).

    cl_abap_unit_assert=>assert_false( act = ls_result-clean ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_result-text CS '<<<<<<< ours' ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_result-text CS '=======' ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_result-text CS '>>>>>>> theirs' ) ).
  ENDMETHOD.

ENDCLASS.
