CLASS zcl_hithub_pr_comments DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_comment,
        repository_id  TYPE string,
        pull_request_id TYPE string,
        comment_id     TYPE string,
        actor          TYPE string,
        body           TYPE string,
        created_at     TYPE string,
      END OF ty_comment,
      ty_comments TYPE STANDARD TABLE OF ty_comment WITH DEFAULT KEY.

    CLASS-METHODS add
      IMPORTING
        is_comment TYPE ty_comment
      RETURNING
        VALUE(rv_saved) TYPE abap_bool.

    CLASS-METHODS list
      IMPORTING
        iv_repository_id   TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rt_comments) TYPE ty_comments.
ENDCLASS.

CLASS zcl_hithub_pr_comments IMPLEMENTATION.

  METHOD add.
    DATA ls_row TYPE zhi_pr_comment.
    DATA ls_existing TYPE zhi_pr_comment.

    CLEAR rv_saved.
    IF is_comment-repository_id IS INITIAL
        OR is_comment-pull_request_id IS INITIAL
        OR is_comment-comment_id IS INITIAL
        OR is_comment-actor IS INITIAL
        OR is_comment-body IS INITIAL
        OR is_comment-created_at IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_pr_comment INTO @ls_existing
      WHERE repository_id = @is_comment-repository_id
        AND pull_request_id = @is_comment-pull_request_id
        AND comment_id = @is_comment-comment_id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = is_comment-repository_id.
    ls_row-pull_request_id = is_comment-pull_request_id.
    ls_row-comment_id = is_comment-comment_id.
    ls_row-actor = is_comment-actor.
    ls_row-body = is_comment-body.
    ls_row-created_at = is_comment-created_at.
    INSERT zhi_pr_comment FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_pr_comment.
    DATA ls_row TYPE zhi_pr_comment.
    DATA ls_comment TYPE ty_comment.

    CLEAR rt_comments.
    IF iv_repository_id IS INITIAL OR iv_pull_request_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_pr_comment INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id
        AND pull_request_id = @iv_pull_request_id.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_comment.
      ls_comment-repository_id = ls_row-repository_id.
      ls_comment-pull_request_id = ls_row-pull_request_id.
      ls_comment-comment_id = ls_row-comment_id.
      ls_comment-actor = ls_row-actor.
      ls_comment-body = ls_row-body.
      ls_comment-created_at = ls_row-created_at.
      APPEND ls_comment TO rt_comments.
    ENDLOOP.
    SORT rt_comments BY comment_id.
  ENDMETHOD.

ENDCLASS.
