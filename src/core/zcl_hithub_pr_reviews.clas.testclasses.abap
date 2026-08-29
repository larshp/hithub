CLASS ltcl_pr_reviews DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS persists_review_states FOR TESTING RAISING cx_static_check.
    METHODS rejects_unknown_state FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pr_reviews IMPLEMENTATION.

  METHOD persists_review_states.
    DATA ls_review TYPE zcl_hithub_pr_reviews=>ty_review.
    DATA lt_reviews TYPE zcl_hithub_pr_reviews=>ty_reviews.
    ls_review-repository_id = 'reviews-repository-1'.
    ls_review-pull_request_id = 'pull-request-1'.
    ls_review-review_id = 'review-1'.
    ls_review-actor = 'maintainer'.
    ls_review-state = zcl_hithub_pr_reviews=>c_approved.
    ls_review-body = 'Looks good.'.
    ls_review-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_pr_reviews=>add( ls_review ) = abap_true.
    lt_reviews = zcl_hithub_pr_reviews=>list(
      iv_repository_id   = ls_review-repository_id
      iv_pull_request_id = ls_review-pull_request_id ).
    ASSERT lines( lt_reviews ) = 1.
    ASSERT lt_reviews[ 1 ]-state = zcl_hithub_pr_reviews=>c_approved.
  ENDMETHOD.

  METHOD rejects_unknown_state.
    DATA ls_review TYPE zcl_hithub_pr_reviews=>ty_review.
    ls_review-repository_id = 'reviews-repository-2'.
    ls_review-pull_request_id = 'pull-request-2'.
    ls_review-review_id = 'review-1'.
    ls_review-actor = 'maintainer'.
    ls_review-state = 'unknown'.
    ls_review-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_pr_reviews=>is_valid_state( ls_review-state ) = abap_false.
    ASSERT zcl_hithub_pr_reviews=>add( ls_review ) = abap_false.
  ENDMETHOD.

ENDCLASS.
