CLASS ltcl_issues DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS creates_open_issue FOR TESTING RAISING cx_static_check.
    METHODS rejects_duplicate_issue FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_issue FOR TESTING RAISING cx_static_check.
    METHODS edits_with_compare_and_swap FOR TESTING RAISING cx_static_check.
    METHODS closes_and_reopens_issue FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_issues IMPLEMENTATION.

  METHOD creates_open_issue.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = 'issue-repository-1'.
    ls_issue-id = 'issue-1'.
    ls_issue-title = 'Document the API'.
    ls_issue-body = 'Add installation examples.'.
    ls_issue-actor = 'Alice <alice@example.test>'.
    DATA(ls_result) = zcl_hithub_issues=>create( ls_issue ).
    ASSERT ls_result-success = abap_true.
    ASSERT ls_result-issue-state = zcl_hithub_issues=>c_open.
    ASSERT ls_result-issue-version = 1.
    ASSERT ls_result-issue-created_at IS NOT INITIAL.
    ASSERT zcl_hithub_issues=>read(
      iv_repository_id = ls_issue-repository_id iv_id = ls_issue-id )-title =
      ls_issue-title.
  ENDMETHOD.

  METHOD rejects_duplicate_issue.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = 'issue-repository-2'.
    ls_issue-id = 'issue-duplicate'.
    ls_issue-title = 'One issue'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_true.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_false.
  ENDMETHOD.

  METHOD rejects_invalid_issue.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = 'issue-repository-3'.
    ls_issue-id = 'issue-invalid'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_false.
  ENDMETHOD.

  METHOD edits_with_compare_and_swap.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = 'issue-repository-4'.
    ls_issue-id = 'issue-edit'.
    ls_issue-title = 'Initial title'.
    ls_issue-body = 'Initial body'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_true.
    DATA(ls_updated) = zcl_hithub_issues=>update(
      iv_repository_id = ls_issue-repository_id iv_id = ls_issue-id
      iv_title = 'Updated title' iv_body = 'Updated body'
      iv_expected_version = 1 ).
    ASSERT ls_updated-success = abap_true.
    ASSERT ls_updated-issue-title = 'Updated title'.
    ASSERT ls_updated-issue-version = 2.
    ASSERT zcl_hithub_issues=>update(
      iv_repository_id = ls_issue-repository_id iv_id = ls_issue-id
      iv_title = 'Stale edit' iv_body = 'Stale body'
      iv_expected_version = 1 )-success = abap_false.
  ENDMETHOD.

  METHOD closes_and_reopens_issue.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = 'issue-repository-5'.
    ls_issue-id = 'issue-state'.
    ls_issue-title = 'State transition'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_true.
    DATA(ls_closed) = zcl_hithub_issues=>transition(
      iv_repository_id = ls_issue-repository_id iv_id = ls_issue-id
      iv_state = zcl_hithub_issues=>c_closed iv_expected_version = 1 ).
    ASSERT ls_closed-success = abap_true.
    ASSERT ls_closed-issue-state = zcl_hithub_issues=>c_closed.
    ASSERT ls_closed-issue-version = 2.
    DATA(ls_reopened) = zcl_hithub_issues=>transition(
      iv_repository_id = ls_issue-repository_id iv_id = ls_issue-id
      iv_state = zcl_hithub_issues=>c_open iv_expected_version = 2 ).
    ASSERT ls_reopened-success = abap_true.
    ASSERT ls_reopened-issue-state = zcl_hithub_issues=>c_open.
    ASSERT zcl_hithub_issues=>transition(
      iv_repository_id = ls_issue-repository_id iv_id = ls_issue-id
      iv_state = zcl_hithub_issues=>c_closed iv_expected_version = 1 )-success =
      abap_false.
  ENDMETHOD.

ENDCLASS.
