CLASS zcl_hithub_merge_policy DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        allowed TYPE abap_bool,
        reason  TYPE string,
      END OF ty_result.

    CLASS-METHODS evaluate
      IMPORTING
        it_rules              TYPE zcl_hithub_branch_protection=>ty_rules
        iv_target_ref         TYPE string
        iv_pull_request_state TYPE string
        iv_mergeability       TYPE string
        iv_approved_reviews   TYPE i
      RETURNING
        VALUE(rs_result)      TYPE ty_result.
ENDCLASS.

CLASS zcl_hithub_merge_policy IMPLEMENTATION.

  METHOD evaluate.
    CLEAR rs_result.
    IF iv_pull_request_state <> zcl_hithub_pull_request_state=>c_open.
      rs_result-reason = 'pull request is not open'.
      RETURN.
    ENDIF.
    IF iv_mergeability <> zcl_hithub_mergeability=>c_clean.
      rs_result-reason = |pull request is { iv_mergeability }|.
      RETURN.
    ENDIF.
    IF zcl_hithub_branch_protection=>allows(
        it_rules = it_rules iv_ref_name = iv_target_ref
        iv_is_delete = abap_false iv_is_force_push = abap_false
        iv_approved_reviews = iv_approved_reviews ) = abap_false.
      rs_result-reason = 'target branch protection rejected the merge'.
      RETURN.
    ENDIF.
    rs_result-allowed = abap_true.
  ENDMETHOD.

ENDCLASS.
