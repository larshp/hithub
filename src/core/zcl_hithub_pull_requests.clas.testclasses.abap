CLASS ltcl_pull_requests DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS creates_and_lists_request FOR TESTING RAISING cx_static_check.
    METHODS rejects_duplicate_request FOR TESTING RAISING cx_static_check.
    METHODS transitions_draft_to_open FOR TESTING RAISING cx_static_check.
    METHODS preserves_review_after_update FOR TESTING RAISING cx_static_check.
    METHODS persists_merged_state FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pull_requests IMPLEMENTATION.

  METHOD creates_and_lists_request.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA ls_result TYPE zcl_hithub_pull_requests=>ty_result.
    DATA lt_requests TYPE zcl_hithub_pr_snapshot=>ty_snapshots.
    ls_request-repository_id = 'pull-requests-repository-1'.
    ls_request-id = 'pull-request-1'.
    ls_request-state = zcl_hithub_pull_request_state=>c_draft.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.

    ls_result = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_true.
    lt_requests = zcl_hithub_pull_requests=>list(
      iv_repository_id = ls_request-repository_id ).
    ASSERT lines( lt_requests ) = 1.
    ASSERT lt_requests[ 1 ]-state = zcl_hithub_pull_request_state=>c_draft.
  ENDMETHOD.

  METHOD rejects_duplicate_request.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA ls_result TYPE zcl_hithub_pull_requests=>ty_result.
    ls_request-repository_id = 'pull-requests-repository-2'.
    ls_request-id = 'pull-request-1'.
    ls_request-state = zcl_hithub_pull_request_state=>c_open.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.

    ls_result = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_true.
    ls_result = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_false.
  ENDMETHOD.

  METHOD transitions_draft_to_open.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA ls_result TYPE zcl_hithub_pull_requests=>ty_result.
    ls_request-repository_id = 'pull-requests-repository-3'.
    ls_request-id = 'pull-request-1'.
    ls_request-state = zcl_hithub_pull_request_state=>c_draft.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.

    ls_result = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_true.
    ls_result = zcl_hithub_pull_requests=>transition(
      iv_repository_id = ls_request-repository_id
      iv_id = ls_request-id
      iv_state = zcl_hithub_pull_request_state=>c_open
      iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_true.
    ASSERT ls_result-pull_request-state = zcl_hithub_pull_request_state=>c_open.
    ASSERT ls_result-pull_request-version = 2.
  ENDMETHOD.

  METHOD preserves_review_after_update.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA ls_result TYPE zcl_hithub_pull_requests=>ty_result.
    DATA ls_review TYPE zcl_hithub_pr_reviews=>ty_review.
    DATA lt_reviews TYPE zcl_hithub_pr_reviews=>ty_reviews.
    ls_request-repository_id = 'pull-requests-repository-4'.
    ls_request-id = 'pull-request-1'.
    ls_request-state = zcl_hithub_pull_request_state=>c_open.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.
    ls_result = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_true.

    ls_review-repository_id = ls_request-repository_id.
    ls_review-pull_request_id = ls_request-id.
    ls_review-review_id = 'review-1'.
    ls_review-actor = 'maintainer'.
    ls_review-state = zcl_hithub_pr_reviews=>c_approved.
    ls_review-created_at = '2026-08-28T12:00:00Z'.
    ASSERT zcl_hithub_pr_reviews=>add( ls_review ) = abap_true.

    ls_result = zcl_hithub_pull_requests=>transition(
      iv_repository_id = ls_request-repository_id
      iv_id = ls_request-id
      iv_state = zcl_hithub_pull_request_state=>c_closed
      iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_true.
    lt_reviews = zcl_hithub_pr_reviews=>list(
      iv_repository_id = ls_request-repository_id
      iv_pull_request_id = ls_request-id ).
    ASSERT lines( lt_reviews ) = 1.
    ASSERT lt_reviews[ 1 ]-state = zcl_hithub_pr_reviews=>c_approved.
  ENDMETHOD.

  METHOD persists_merged_state.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA ls_result TYPE zcl_hithub_pull_requests=>ty_result.
    DATA ls_read TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_request-repository_id = 'pull-requests-repository-5'.
    ls_request-id = 'pull-request-1'.
    ls_request-state = zcl_hithub_pull_request_state=>c_open.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.
    ls_result = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_true.
    ls_result = zcl_hithub_pull_requests=>transition(
      iv_repository_id = ls_request-repository_id iv_id = ls_request-id
      iv_state = zcl_hithub_pull_request_state=>c_merged
      iv_expected_version = 1 ).
    ASSERT ls_result-success = abap_true.
    ls_read = zcl_hithub_pull_requests=>find(
      iv_repository_id = ls_request-repository_id iv_id = ls_request-id ).
    ASSERT ls_read-state = zcl_hithub_pull_request_state=>c_merged.
  ENDMETHOD.

ENDCLASS.
