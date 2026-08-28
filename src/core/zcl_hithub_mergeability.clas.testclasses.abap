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
    ASSERT zcl_hithub_mergeability=>evaluate(
      iv_head_oid = 'head' iv_expected_head_oid = 'head'
      iv_base_oid = 'base' iv_expected_base_oid = 'base'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_clean.
  ENDMETHOD.

  METHOD returns_conflict_state.
    ASSERT zcl_hithub_mergeability=>evaluate(
      iv_head_oid = 'head' iv_expected_head_oid = 'head'
      iv_base_oid = 'base' iv_expected_base_oid = 'base'
      iv_merge_clean = abap_false iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_conflicting.
  ENDMETHOD.

  METHOD returns_stale_state.
    ASSERT zcl_hithub_mergeability=>evaluate(
      iv_head_oid = 'new-head' iv_expected_head_oid = 'old-head'
      iv_base_oid = 'base' iv_expected_base_oid = 'base'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_stale.
  ENDMETHOD.

  METHOD returns_blocked_state.
    ASSERT zcl_hithub_mergeability=>evaluate(
      iv_head_oid = 'head' iv_expected_head_oid = 'head'
      iv_base_oid = 'base' iv_expected_base_oid = 'base'
      iv_merge_clean = abap_true iv_blocked = abap_true ) =
        zcl_hithub_mergeability=>c_blocked.
  ENDMETHOD.

  METHOD returns_unknown_state.
    ASSERT zcl_hithub_mergeability=>evaluate(
      iv_head_oid = '' iv_expected_head_oid = 'head'
      iv_base_oid = 'base' iv_expected_base_oid = 'base'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_unknown.
  ENDMETHOD.

ENDCLASS.
