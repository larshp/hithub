CLASS ltcl_mergeability DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS returns_clean_state FOR TESTING RAISING cx_static_check.
    METHODS returns_conflict_state FOR TESTING RAISING cx_static_check.
    METHODS returns_stale_state FOR TESTING RAISING cx_static_check.
    METHODS returns_blocked_state FOR TESTING RAISING cx_static_check.
    METHODS returns_unknown_state FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_mergeability IMPLEMENTATION.

  METHOD returns_clean_state.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_mergeability=>evaluate(
        iv_head_oid = 'head' iv_expected_head_oid = 'head'
        iv_base_oid = 'base' iv_expected_base_oid = 'base'
        iv_merge_clean = abap_true iv_blocked = abap_false )
      exp = zcl_hithub_mergeability=>c_clean ).
  ENDMETHOD.

  METHOD returns_conflict_state.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_mergeability=>evaluate(
        iv_head_oid = 'head' iv_expected_head_oid = 'head'
        iv_base_oid = 'base' iv_expected_base_oid = 'base'
        iv_merge_clean = abap_false iv_blocked = abap_false )
      exp = zcl_hithub_mergeability=>c_conflicting ).
  ENDMETHOD.

  METHOD returns_stale_state.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_mergeability=>evaluate(
        iv_head_oid = 'new-head' iv_expected_head_oid = 'old-head'
        iv_base_oid = 'base' iv_expected_base_oid = 'base'
        iv_merge_clean = abap_true iv_blocked = abap_false )
      exp = zcl_hithub_mergeability=>c_stale ).
  ENDMETHOD.

  METHOD returns_blocked_state.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_mergeability=>evaluate(
        iv_head_oid = 'head' iv_expected_head_oid = 'head'
        iv_base_oid = 'base' iv_expected_base_oid = 'base'
        iv_merge_clean = abap_true iv_blocked = abap_true )
      exp = zcl_hithub_mergeability=>c_blocked ).
  ENDMETHOD.

  METHOD returns_unknown_state.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_mergeability=>evaluate(
        iv_head_oid = '' iv_expected_head_oid = 'head'
        iv_base_oid = 'base' iv_expected_base_oid = 'base'
        iv_merge_clean = abap_true iv_blocked = abap_false )
      exp = zcl_hithub_mergeability=>c_unknown ).
  ENDMETHOD.

ENDCLASS.
