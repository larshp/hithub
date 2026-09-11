CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS rejects_integer_overflow FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD rejects_integer_overflow.
    DATA lv_max TYPE int8.
    DATA ls_result TYPE zcl_hithub_pack_arithmetic=>ty_result.

    lv_max = CONV int8( '9223372036854775807' ).
    ls_result = zcl_hithub_pack_arithmetic=>add( iv_left = 4 iv_right = 5 ).
    cl_abap_unit_assert=>assert_true( act = ls_result-safe ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-result exp = 9 ).
    ls_result = zcl_hithub_pack_arithmetic=>add( iv_left = lv_max iv_right = 1 ).
    cl_abap_unit_assert=>assert_false( act = ls_result-safe ).
    ls_result = zcl_hithub_pack_arithmetic=>multiply( iv_left = lv_max iv_right = 2 ).
    cl_abap_unit_assert=>assert_false( act = ls_result-safe ).
    ls_result = zcl_hithub_pack_arithmetic=>multiply( iv_left = -1 iv_right = 2 ).
    cl_abap_unit_assert=>assert_false( act = ls_result-safe ).
  ENDMETHOD.

ENDCLASS.
