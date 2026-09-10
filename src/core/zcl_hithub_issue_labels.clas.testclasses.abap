CLASS ltcl_issue_labels DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS manages_labels FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_issue_labels IMPLEMENTATION.

  METHOD manages_labels.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_issue_labels=>add(
        iv_repository_id = 'issue-label-repository'
        iv_issue_id = 'issue-1' iv_label = 'bug' ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_issue_labels=>add(
        iv_repository_id = 'issue-label-repository'
        iv_issue_id = 'issue-1' iv_label = 'help wanted' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_issue_labels=>add(
        iv_repository_id = 'issue-label-repository'
        iv_issue_id = 'issue-1' iv_label = 'bug' ) ).
    DATA(lt_labels) = zcl_hithub_issue_labels=>list(
      iv_repository_id = 'issue-label-repository' iv_issue_id = 'issue-1' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_labels ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_labels[ 1 ] exp = 'bug' ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_issue_labels=>remove(
        iv_repository_id = 'issue-label-repository'
        iv_issue_id = 'issue-1' iv_label = 'bug' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( zcl_hithub_issue_labels=>list(
        iv_repository_id = 'issue-label-repository'
        iv_issue_id      = 'issue-1' ) )
      exp = 1 ).
  ENDMETHOD.

ENDCLASS.
