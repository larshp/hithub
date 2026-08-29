CLASS ltcl_line_comments DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS persists_coordinates FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_line FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_line_comments IMPLEMENTATION.

  METHOD persists_coordinates.
    DATA ls_comment TYPE zcl_hithub_line_comments=>ty_comment.
    DATA lt_comments TYPE zcl_hithub_line_comments=>ty_comments.
    ls_comment-repository_id = 'line-comments-repository-1'.
    ls_comment-pull_request_id = 'pull-request-1'.
    ls_comment-comment_id = 'line-comment-1'.
    ls_comment-commit_oid = 'commit-1'.
    ls_comment-path = 'src/main.abap'.
    ls_comment-line_number = 42.
    ls_comment-actor = 'reviewer'.
    ls_comment-body = 'Can this be simplified?'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_line_comments=>add( ls_comment ) = abap_true.
    lt_comments = zcl_hithub_line_comments=>list(
      iv_repository_id   = ls_comment-repository_id
      iv_pull_request_id = ls_comment-pull_request_id ).
    ASSERT lines( lt_comments ) = 1.
    ASSERT lt_comments[ 1 ]-commit_oid = 'commit-1'.
    ASSERT lt_comments[ 1 ]-path = 'src/main.abap'.
    ASSERT lt_comments[ 1 ]-line_number = 42.
  ENDMETHOD.

  METHOD rejects_invalid_line.
    DATA ls_comment TYPE zcl_hithub_line_comments=>ty_comment.
    ls_comment-repository_id = 'line-comments-repository-2'.
    ls_comment-pull_request_id = 'pull-request-2'.
    ls_comment-comment_id = 'line-comment-1'.
    ls_comment-commit_oid = 'commit-1'.
    ls_comment-path = 'src/main.abap'.
    ls_comment-line_number = 0.
    ls_comment-actor = 'reviewer'.
    ls_comment-body = 'Invalid coordinate.'.
    ls_comment-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_line_comments=>add( ls_comment ) = abap_false.
  ENDMETHOD.

ENDCLASS.
