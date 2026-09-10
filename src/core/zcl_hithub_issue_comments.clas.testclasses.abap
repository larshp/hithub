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
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_issue_comments=>add( ls_comment ) ).
    ls_comment-comment_id = 'comment-1'.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_issue_comments=>add( ls_comment ) ).
    DATA(lt_comments) = zcl_hithub_issue_comments=>list(
      iv_repository_id = ls_comment-repository_id
      iv_issue_id      = ls_comment-issue_id ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_comments ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_comments[ 1 ]-comment_id
      exp = 'comment-1' ).
  ENDMETHOD.

  METHOD rejects_duplicate_comment.
    DATA ls_comment TYPE zcl_hithub_issue_comments=>ty_comment.
    ls_comment-repository_id = 'issue-comment-repository-2'.
    ls_comment-issue_id = 'issue-2'.
    ls_comment-comment_id = 'comment-1'.
    ls_comment-actor = 'Alice'.
    ls_comment-body = 'A comment.'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_issue_comments=>add( ls_comment ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_issue_comments=>add( ls_comment ) ).
  ENDMETHOD.

ENDCLASS.
