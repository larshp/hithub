CLASS zcl_hithub_pr_recompute DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS for_head_change
      IMPORTING
        is_snapshot         TYPE zcl_hithub_pr_snapshot=>ty_snapshot
        iv_current_head_oid TYPE string
        iv_merge_clean      TYPE abap_bool
        iv_blocked          TYPE abap_bool
      RETURNING
        VALUE(rv_state)     TYPE string.

    CLASS-METHODS for_base_change
      IMPORTING
        is_snapshot         TYPE zcl_hithub_pr_snapshot=>ty_snapshot
        iv_current_base_oid TYPE string
        iv_merge_clean      TYPE abap_bool
        iv_blocked          TYPE abap_bool
      RETURNING
        VALUE(rv_state)     TYPE string.
ENDCLASS.

CLASS zcl_hithub_pr_recompute IMPLEMENTATION.

  METHOD for_head_change.
    rv_state = zcl_hithub_mergeability=>evaluate(
      iv_head_oid          = iv_current_head_oid
      iv_expected_head_oid = is_snapshot-head_oid
      iv_base_oid          = is_snapshot-base_oid
      iv_expected_base_oid = is_snapshot-base_oid
      iv_merge_clean       = iv_merge_clean
      iv_blocked           = iv_blocked ).
  ENDMETHOD.

  METHOD for_base_change.
    rv_state = zcl_hithub_mergeability=>evaluate(
      iv_head_oid          = is_snapshot-head_oid
      iv_expected_head_oid = is_snapshot-head_oid
      iv_base_oid          = iv_current_base_oid
      iv_expected_base_oid = is_snapshot-base_oid
      iv_merge_clean       = iv_merge_clean
      iv_blocked           = iv_blocked ).
  ENDMETHOD.

ENDCLASS.
