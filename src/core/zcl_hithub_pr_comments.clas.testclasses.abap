CLASS ltcl_pr_comments DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS persists_and_lists_comments FOR TESTING RAISING cx_static_check.
    METHODS rejects_duplicate_comment FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pr_comments IMPLEMENTATION.

  METHOD persists_and_lists_comments.
    DATA ls_comment TYPE zcl_hithub_pr_comments=>ty_comment.
    DATA lt_comments TYPE zcl_hithub_pr_comments=>ty_comments.
    ls_comment-repository_id = 'comments-repository-1'.
    ls_comment-pull_request_id = 'pull-request-1'.
    ls_comment-comment_id = 'comment-1'.
    ls_comment-actor = 'reviewer'.
    ls_comment-body = 'Please add a test.'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_pr_comments=>add( ls_comment ) = abap_true.
    lt_comments = zcl_hithub_pr_comments=>list(
      iv_repository_id   = ls_comment-repository_id
      iv_pull_request_id = ls_comment-pull_request_id ).
    ASSERT lines( lt_comments ) = 1.
    ASSERT lt_comments[ 1 ]-actor = 'reviewer'.
    ASSERT lt_comments[ 1 ]-body = 'Please add a test.'.
  ENDMETHOD.

  METHOD rejects_duplicate_comment.
    DATA ls_comment TYPE zcl_hithub_pr_comments=>ty_comment.
    ls_comment-repository_id = 'comments-repository-2'.
    ls_comment-pull_request_id = 'pull-request-2'.
    ls_comment-comment_id = 'comment-1'.
    ls_comment-actor = 'reviewer'.
    ls_comment-body = 'First comment.'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_pr_comments=>add( ls_comment ) = abap_true.
    ASSERT zcl_hithub_pr_comments=>add( ls_comment ) = abap_false.
  ENDMETHOD.

ENDCLASS.
