CLASS ltcl_work_number DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS shares_one_sequence FOR TESTING RAISING cx_static_check.
    METHODS ignores_non_numeric_identities FOR TESTING RAISING cx_static_check.
    METHODS parses_only_plain_numbers FOR TESTING RAISING cx_static_check.

    METHODS open_issue
      IMPORTING
        iv_repository_id TYPE string
      RETURNING
        VALUE(rv_id)     TYPE string.

    METHODS open_pull_request
      IMPORTING
        iv_repository_id TYPE string
      RETURNING
        VALUE(rv_id)     TYPE string.
ENDCLASS.

CLASS ltcl_work_number IMPLEMENTATION.

  METHOD open_issue.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = iv_repository_id.
    ls_issue-title = 'Reported'.
    ls_issue-actor = 'Alice'.
    DATA(ls_result) = zcl_hithub_issues=>create( ls_issue ).
    ASSERT ls_result-success = abap_true.
    rv_id = ls_result-issue-id.
  ENDMETHOD.

  METHOD open_pull_request.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_request-repository_id = iv_repository_id.
    ls_request-state = zcl_hithub_pull_request_state=>c_draft.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.
    DATA(ls_result) = zcl_hithub_pull_requests=>create( ls_request ).
    ASSERT ls_result-success = abap_true.
    rv_id = ls_result-pull_request-id.
  ENDMETHOD.

  METHOD shares_one_sequence.
    DATA(lv_repository) = 'work-number-shared'.

    ASSERT open_issue( lv_repository ) = '1'.
    ASSERT open_pull_request( lv_repository ) = '2'.
    ASSERT open_pull_request( lv_repository ) = '3'.
    ASSERT open_issue( lv_repository ) = '4'.
    ASSERT open_issue( lv_repository ) = '5'.
    ASSERT open_pull_request( lv_repository ) = '6'.
    " A second repository starts its own sequence at one.
    ASSERT open_pull_request( 'work-number-other' ) = '1'.
  ENDMETHOD.

  METHOD ignores_non_numeric_identities.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA(lv_repository) = 'work-number-legacy'.

    ls_issue-repository_id = lv_repository.
    ls_issue-id = 'legacy-issue-uuid'.
    ls_issue-title = 'Imported before numbering'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_true.
    ls_request-repository_id = lv_repository.
    ls_request-id = 'legacy-pull-uuid'.
    ls_request-state = zcl_hithub_pull_request_state=>c_draft.
    ls_request-source_ref = 'refs/heads/feature'.
    ls_request-target_ref = 'refs/heads/main'.
    ls_request-base_oid = 'base'.
    ls_request-head_oid = 'head'.
    ASSERT zcl_hithub_pull_requests=>create( ls_request )-success = abap_true.

    ASSERT zcl_hithub_work_number=>next( lv_repository ) = 1.
    ASSERT open_issue( lv_repository ) = '1'.
    ASSERT open_pull_request( lv_repository ) = '2'.
  ENDMETHOD.

  METHOD parses_only_plain_numbers.
    ASSERT zcl_hithub_work_number=>parse( '7' ) = 7.
    ASSERT zcl_hithub_work_number=>parse( '10' ) = 10.
    ASSERT zcl_hithub_work_number=>parse( '' ) = 0.
    ASSERT zcl_hithub_work_number=>parse( 'pull-1' ) = 0.
    ASSERT zcl_hithub_work_number=>parse( '1a' ) = 0.
    ASSERT zcl_hithub_work_number=>parse( '1234567890' ) = 0.
    ASSERT zcl_hithub_work_number=>next( '' ) = 0.
  ENDMETHOD.

ENDCLASS.
