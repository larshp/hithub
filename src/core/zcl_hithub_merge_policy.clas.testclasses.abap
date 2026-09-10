CLASS ltcl_merge_policy DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS allows_clean_open_request FOR TESTING RAISING cx_static_check.
    METHODS rejects_non_clean_request FOR TESTING RAISING cx_static_check.
    METHODS rejects_insufficient_review FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_policy IMPLEMENTATION.

  METHOD allows_clean_open_request.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.
    DATA ls_result TYPE zcl_hithub_merge_policy=>ty_result.
    APPEND VALUE #( pattern = 'refs/heads/main' required_reviews = 1 )
      TO lt_rules.
    ls_result = zcl_hithub_merge_policy=>evaluate(
      it_rules = lt_rules iv_target_ref = 'refs/heads/main'
      iv_pull_request_state = zcl_hithub_pull_request_state=>c_open
      iv_mergeability = zcl_hithub_mergeability=>c_clean
      iv_approved_reviews = 1 ).
    cl_abap_unit_assert=>assert_true( act = ls_result-allowed ).
    cl_abap_unit_assert=>assert_initial( act = ls_result-reason ).
  ENDMETHOD.

  METHOD rejects_non_clean_request.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.
    DATA ls_result TYPE zcl_hithub_merge_policy=>ty_result.
    ls_result = zcl_hithub_merge_policy=>evaluate(
      it_rules = lt_rules iv_target_ref = 'refs/heads/main'
      iv_pull_request_state = zcl_hithub_pull_request_state=>c_open
      iv_mergeability = zcl_hithub_mergeability=>c_conflicting
      iv_approved_reviews = 0 ).
    cl_abap_unit_assert=>assert_false( act = ls_result-allowed ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'pull request is conflicting' ).
  ENDMETHOD.

  METHOD rejects_insufficient_review.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.
    DATA ls_result TYPE zcl_hithub_merge_policy=>ty_result.
    APPEND VALUE #( pattern = 'refs/heads/main' required_reviews = 2 )
      TO lt_rules.
    ls_result = zcl_hithub_merge_policy=>evaluate(
      it_rules = lt_rules iv_target_ref = 'refs/heads/main'
      iv_pull_request_state = zcl_hithub_pull_request_state=>c_open
      iv_mergeability = zcl_hithub_mergeability=>c_clean
      iv_approved_reviews = 1 ).
    cl_abap_unit_assert=>assert_false( act = ls_result-allowed ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'target branch protection rejected the merge' ).
  ENDMETHOD.

ENDCLASS.
