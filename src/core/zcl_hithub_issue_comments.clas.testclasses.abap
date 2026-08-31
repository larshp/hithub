CLASS ltcl_issue_comments DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS persists_and_lists_comments FOR TESTING RAISING cx_static_check.
    METHODS rejects_duplicate_comment FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_issue_comments IMPLEMENTATION.

  METHOD persists_and_lists_comments.
    DATA ls_comment TYPE zcl_hithub_issue_comments=>ty_comment.
    ls_comment-repository_id = 'issue-comment-repository-1'.
    ls_comment-issue_id = 'issue-1'.
    ls_comment-comment_id = 'comment-2'.
    ls_comment-actor = 'Alice'.
    ls_comment-body = 'Please add an example.'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.
    ASSERT zcl_hithub_issue_comments=>add( ls_comment ) = abap_true.
    ls_comment-comment_id = 'comment-1'.
    ASSERT zcl_hithub_issue_comments=>add( ls_comment ) = abap_true.
    DATA(lt_comments) = zcl_hithub_issue_comments=>list(
      iv_repository_id = ls_comment-repository_id
      iv_issue_id      = ls_comment-issue_id ).
    ASSERT lines( lt_comments ) = 2.
    ASSERT lt_comments[ 1 ]-comment_id = 'comment-1'.
  ENDMETHOD.

  METHOD rejects_duplicate_comment.
    DATA ls_comment TYPE zcl_hithub_issue_comments=>ty_comment.
    ls_comment-repository_id = 'issue-comment-repository-2'.
    ls_comment-issue_id = 'issue-2'.
    ls_comment-comment_id = 'comment-1'.
    ls_comment-actor = 'Alice'.
    ls_comment-body = 'A comment.'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.
    ASSERT zcl_hithub_issue_comments=>add( ls_comment ) = abap_true.
    ASSERT zcl_hithub_issue_comments=>add( ls_comment ) = abap_false.
  ENDMETHOD.

ENDCLASS.
