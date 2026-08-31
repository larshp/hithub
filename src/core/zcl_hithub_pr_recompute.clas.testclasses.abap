CLASS ltcl_pr_recompute DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS marks_changed_head_stale FOR TESTING RAISING cx_static_check.
    METHODS recalculates_unchanged_head FOR TESTING RAISING cx_static_check.
    METHODS marks_changed_base_stale FOR TESTING RAISING cx_static_check.
    METHODS marks_concurrent_base_movement FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pr_recompute IMPLEMENTATION.

  METHOD marks_changed_head_stale.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-head_oid = 'old-head'.
    ls_snapshot-base_oid = 'base'.
    ASSERT zcl_hithub_pr_recompute=>for_head_change(
      is_snapshot = ls_snapshot iv_current_head_oid = 'new-head'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_stale.
  ENDMETHOD.

  METHOD recalculates_unchanged_head.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-head_oid = 'head'.
    ls_snapshot-base_oid = 'base'.
    ASSERT zcl_hithub_pr_recompute=>for_head_change(
      is_snapshot = ls_snapshot iv_current_head_oid = 'head'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_clean.
  ENDMETHOD.

  METHOD marks_changed_base_stale.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-head_oid = 'head'.
    ls_snapshot-base_oid = 'old-base'.
    ASSERT zcl_hithub_pr_recompute=>for_base_change(
      is_snapshot = ls_snapshot iv_current_base_oid = 'new-base'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_stale.
  ENDMETHOD.

  METHOD marks_concurrent_base_movement.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-head_oid = 'head'.
    ls_snapshot-base_oid = 'base-before-race'.
    ASSERT zcl_hithub_pr_recompute=>for_base_change(
      is_snapshot = ls_snapshot iv_current_base_oid = 'base-after-race'
      iv_merge_clean = abap_true iv_blocked = abap_false ) =
        zcl_hithub_mergeability=>c_stale.
  ENDMETHOD.

ENDCLASS.
