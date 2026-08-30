CLASS zcl_hithub_pull_requests DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_number_attempts TYPE i VALUE 25.
    TYPES:
      BEGIN OF ty_result,
        success      TYPE abap_bool,
        reason       TYPE string,
        pull_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot,
      END OF ty_result.

    CLASS-METHODS create
      IMPORTING
        is_pull_request  TYPE zcl_hithub_pr_snapshot=>ty_snapshot
      RETURNING
        VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS find
      IMPORTING
        iv_repository_id       TYPE string
        iv_id                  TYPE string
      RETURNING
        VALUE(rs_pull_request) TYPE zcl_hithub_pr_snapshot=>ty_snapshot.

    CLASS-METHODS list
      IMPORTING
        iv_repository_id        TYPE string
      RETURNING
        VALUE(rt_pull_requests) TYPE zcl_hithub_pr_snapshot=>ty_snapshots.

    CLASS-METHODS transition
      IMPORTING
        iv_repository_id    TYPE string
        iv_id               TYPE string
        iv_state            TYPE string
        iv_expected_version TYPE int8
      RETURNING
        VALUE(rs_result)    TYPE ty_result.
ENDCLASS.

CLASS zcl_hithub_pull_requests IMPLEMENTATION.

  METHOD create.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA lv_assign_number TYPE abap_bool.
    DATA lv_attempt TYPE i.
    DATA lv_number TYPE i.

    CLEAR rs_result.
    ls_request = is_pull_request.
    lv_assign_number = xsdbool( ls_request-id IS INITIAL ).
    IF zcl_hithub_pr_snapshot=>is_valid(
        is_snapshot   = ls_request
        iv_require_id = xsdbool( lv_assign_number = abap_false ) ) = abap_false.
      rs_result-reason = 'pull request is invalid or already exists'.
      RETURN.
    ENDIF.
    IF lv_assign_number = abap_false.
      IF zcl_hithub_pr_snapshot=>open( ls_request ) = abap_false.
        rs_result-reason = 'pull request is invalid or already exists'.
        RETURN.
      ENDIF.
      rs_result-success = abap_true.
      rs_result-pull_request = ls_request.
      rs_result-pull_request-version = 1.
      RETURN.
    ENDIF.

    " A concurrent writer can claim the same number between the scan and the
    " insert; the primary key rejects the loser, which then takes the next one.
    lv_attempt = 1.
    WHILE lv_attempt <= c_number_attempts.
      lv_number = zcl_hithub_work_number=>next( ls_request-repository_id ).
      IF lv_number <= 0.
        rs_result-reason = 'pull request number could not be assigned'.
        RETURN.
      ENDIF.
      ls_request-id = |{ lv_number }|.
      IF zcl_hithub_pr_snapshot=>open( ls_request ) = abap_true.
        rs_result-success = abap_true.
        rs_result-pull_request = ls_request.
        rs_result-pull_request-version = 1.
        RETURN.
      ENDIF.
      lv_attempt = lv_attempt + 1.
    ENDWHILE.
    rs_result-reason = 'pull request number could not be assigned'.
  ENDMETHOD.

  METHOD find.
    rs_pull_request = zcl_hithub_pr_snapshot=>read(
      iv_repository_id = iv_repository_id iv_id = iv_id ).
  ENDMETHOD.

  METHOD list.
    TYPES:
      BEGIN OF ty_ordered,
        number       TYPE i,
        id           TYPE string,
        pull_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot,
      END OF ty_ordered.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_pull_request.
    DATA ls_row TYPE zhi_pull_request.
    DATA ls_pull_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA lt_ordered TYPE STANDARD TABLE OF ty_ordered WITH DEFAULT KEY.
    DATA ls_ordered TYPE ty_ordered.

    CLEAR rt_pull_requests.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_pull_request INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_pull_request.
      ls_pull_request-repository_id = ls_row-repository_id.
      ls_pull_request-id = ls_row-id.
      ls_pull_request-state = ls_row-state.
      ls_pull_request-source_ref = ls_row-source_ref.
      ls_pull_request-target_ref = ls_row-target_ref.
      ls_pull_request-base_oid = ls_row-base_oid.
      ls_pull_request-head_oid = ls_row-head_oid.
      ls_pull_request-version = ls_row-version.
      CLEAR ls_ordered.
      ls_ordered-number = zcl_hithub_work_number=>parse( ls_pull_request-id ).
      ls_ordered-id = ls_pull_request-id.
      ls_ordered-pull_request = ls_pull_request.
      APPEND ls_ordered TO lt_ordered.
    ENDLOOP.
    " Newest first, and numerically so that #10 outranks #9.
    SORT lt_ordered BY number DESCENDING id DESCENDING.
    LOOP AT lt_ordered INTO ls_ordered.
      APPEND ls_ordered-pull_request TO rt_pull_requests.
    ENDLOOP.
  ENDMETHOD.

  METHOD transition.
    DATA ls_row TYPE zhi_pull_request.
    DATA ls_current TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA lv_current_state TYPE string.

    CLEAR rs_result.
    IF iv_repository_id IS INITIAL OR iv_id IS INITIAL
        OR iv_expected_version <= 0.
      rs_result-reason = 'pull request transition is invalid'.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_pull_request INTO @ls_row
      WHERE repository_id = @iv_repository_id AND id = @iv_id.
    IF sy-subrc <> 0.
      rs_result-reason = 'pull request was not found'.
      RETURN.
    ENDIF.
    IF ls_row-version <> iv_expected_version.
      rs_result-reason = 'pull request version is stale'.
      RETURN.
    ENDIF.
    lv_current_state = ls_row-state.
    IF zcl_hithub_pull_request_state=>can_transition(
        iv_from = lv_current_state iv_to = iv_state ) = abap_false.
      rs_result-reason = 'pull request state transition is invalid'.
      RETURN.
    ENDIF.
    ls_row-state = iv_state.
    ls_row-version = ls_row-version + 1.
    UPDATE zhi_pull_request FROM @ls_row.
    IF sy-subrc <> 0.
      rs_result-reason = 'pull request update failed'.
      RETURN.
    ENDIF.
    ls_current-repository_id = ls_row-repository_id.
    ls_current-id = ls_row-id.
    ls_current-state = ls_row-state.
    ls_current-source_ref = ls_row-source_ref.
    ls_current-target_ref = ls_row-target_ref.
    ls_current-base_oid = ls_row-base_oid.
    ls_current-head_oid = ls_row-head_oid.
    ls_current-version = ls_row-version.
    rs_result-success = abap_true.
    rs_result-pull_request = ls_current.
  ENDMETHOD.

ENDCLASS.
