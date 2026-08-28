CLASS zcl_hithub_pr_reviews DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_approved TYPE string VALUE 'approved'.
    CONSTANTS c_request_changes TYPE string VALUE 'request_changes'.
    CONSTANTS c_commented TYPE string VALUE 'commented'.
    TYPES:
      BEGIN OF ty_review,
        repository_id   TYPE string,
        pull_request_id TYPE string,
        review_id       TYPE string,
        actor           TYPE string,
        state           TYPE string,
        body            TYPE string,
        created_at      TYPE string,
      END OF ty_review,
      ty_reviews TYPE STANDARD TABLE OF ty_review WITH DEFAULT KEY.

    CLASS-METHODS is_valid_state
      IMPORTING
        iv_state TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    CLASS-METHODS add
      IMPORTING
        is_review TYPE ty_review
      RETURNING
        VALUE(rv_saved) TYPE abap_bool.

    CLASS-METHODS list
      IMPORTING
        iv_repository_id   TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rt_reviews) TYPE ty_reviews.
ENDCLASS.

CLASS zcl_hithub_pr_reviews IMPLEMENTATION.

  METHOD is_valid_state.
    rv_valid = xsdbool( iv_state = c_approved
      OR iv_state = c_request_changes OR iv_state = c_commented ).
  ENDMETHOD.

  METHOD add.
    DATA ls_row TYPE zhi_pr_review.
    DATA ls_existing TYPE zhi_pr_review.

    CLEAR rv_saved.
    IF is_review-repository_id IS INITIAL
        OR is_review-pull_request_id IS INITIAL
        OR is_review-review_id IS INITIAL
        OR is_review-actor IS INITIAL
        OR is_review-created_at IS INITIAL
        OR is_valid_state( is_review-state ) = abap_false.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_pr_review INTO @ls_existing
      WHERE repository_id = @is_review-repository_id
        AND pull_request_id = @is_review-pull_request_id
        AND review_id = @is_review-review_id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = is_review-repository_id.
    ls_row-pull_request_id = is_review-pull_request_id.
    ls_row-review_id = is_review-review_id.
    ls_row-actor = is_review-actor.
    ls_row-state = is_review-state.
    ls_row-body = is_review-body.
    ls_row-created_at = is_review-created_at.
    INSERT zhi_pr_review FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_pr_review.
    DATA ls_row TYPE zhi_pr_review.
    DATA ls_review TYPE ty_review.

    CLEAR rt_reviews.
    IF iv_repository_id IS INITIAL OR iv_pull_request_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_pr_review INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id
        AND pull_request_id = @iv_pull_request_id.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_review.
      ls_review-repository_id = ls_row-repository_id.
      ls_review-pull_request_id = ls_row-pull_request_id.
      ls_review-review_id = ls_row-review_id.
      ls_review-actor = ls_row-actor.
      ls_review-state = ls_row-state.
      ls_review-body = ls_row-body.
      ls_review-created_at = ls_row-created_at.
      APPEND ls_review TO rt_reviews.
    ENDLOOP.
    SORT rt_reviews BY review_id.
  ENDMETHOD.

ENDCLASS.
