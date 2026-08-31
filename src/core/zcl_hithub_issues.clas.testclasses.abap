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
    METHODS numbers_issues_sequentially FOR TESTING RAISING cx_static_check.
    METHODS skips_numbers_already_taken FOR TESTING RAISING cx_static_check.
    METHODS lists_newest_number_first FOR TESTING RAISING cx_static_check.

    METHODS open_issue
      IMPORTING
        iv_repository_id TYPE string
        iv_title         TYPE string
      RETURNING
        VALUE(rv_id)     TYPE string.
ENDCLASS.

CLASS ltcl_issues IMPLEMENTATION.

  METHOD open_issue.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    ls_issue-repository_id = iv_repository_id.
    ls_issue-title = iv_title.
    ls_issue-actor = 'Alice'.
    DATA(ls_result) = zcl_hithub_issues=>create( ls_issue ).
    ASSERT ls_result-success = abap_true.
    rv_id = ls_result-issue-id.
  ENDMETHOD.

  METHOD numbers_issues_sequentially.
    DATA(lv_repository) = 'issue-numbering-1'.
    ASSERT open_issue(
      iv_repository_id = lv_repository iv_title = 'First' ) = '1'.
    ASSERT open_issue(
      iv_repository_id = lv_repository iv_title = 'Second' ) = '2'.
    ASSERT open_issue(
      iv_repository_id = lv_repository iv_title = 'Third' ) = '3'.
    " Numbers restart per repository rather than continuing globally.
    ASSERT open_issue(
      iv_repository_id = 'issue-numbering-2' iv_title = 'Elsewhere' ) = '1'.
  ENDMETHOD.

  METHOD skips_numbers_already_taken.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    DATA(lv_repository) = 'issue-numbering-3'.
    ls_issue-repository_id = lv_repository.
    ls_issue-id = '4'.
    ls_issue-title = 'Imported with an explicit number'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_true.
    " Legacy non-numeric identities never take part in the sequence.
    CLEAR ls_issue.
    ls_issue-repository_id = lv_repository.
    ls_issue-id = 'legacy-uuid-identity'.
    ls_issue-title = 'Imported before numbering'.
    ls_issue-actor = 'Alice'.
    ASSERT zcl_hithub_issues=>create( ls_issue )-success = abap_true.
    ASSERT open_issue(
      iv_repository_id = lv_repository iv_title = 'Next' ) = '5'.
  ENDMETHOD.

  METHOD lists_newest_number_first.
    DATA(lv_repository) = 'issue-numbering-4'.
    DATA lv_index TYPE i.
    DATA lt_issues TYPE zcl_hithub_issues=>ty_issues.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.

    lv_index = 1.
    WHILE lv_index <= 11.
      open_issue(
        iv_repository_id = lv_repository iv_title = |Issue { lv_index }| ).
      lv_index = lv_index + 1.
    ENDWHILE.
    lt_issues = zcl_hithub_issues=>list( lv_repository ).
    ASSERT lines( lt_issues ) = 11.
    READ TABLE lt_issues INDEX 1 INTO ls_issue.
    ASSERT ls_issue-id = '11'.
    READ TABLE lt_issues INDEX 2 INTO ls_issue.
    ASSERT ls_issue-id = '10'.
    READ TABLE lt_issues INDEX 11 INTO ls_issue.
    ASSERT ls_issue-id = '1'.
  ENDMETHOD.

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
