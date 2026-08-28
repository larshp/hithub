CLASS ltcl_issue_labels DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS manages_labels FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_issue_labels IMPLEMENTATION.

  METHOD manages_labels.
    ASSERT zcl_hithub_issue_labels=>add(
      iv_repository_id = 'issue-label-repository'
      iv_issue_id = 'issue-1' iv_label = 'bug' ) = abap_true.
    ASSERT zcl_hithub_issue_labels=>add(
      iv_repository_id = 'issue-label-repository'
      iv_issue_id = 'issue-1' iv_label = 'help wanted' ) = abap_true.
    ASSERT zcl_hithub_issue_labels=>add(
      iv_repository_id = 'issue-label-repository'
      iv_issue_id = 'issue-1' iv_label = 'bug' ) = abap_false.
    DATA(lt_labels) = zcl_hithub_issue_labels=>list(
      iv_repository_id = 'issue-label-repository' iv_issue_id = 'issue-1' ).
    ASSERT lines( lt_labels ) = 2.
    ASSERT lt_labels[ 1 ] = 'bug'.
    ASSERT zcl_hithub_issue_labels=>remove(
      iv_repository_id = 'issue-label-repository'
      iv_issue_id = 'issue-1' iv_label = 'bug' ) = abap_true.
    ASSERT lines( zcl_hithub_issue_labels=>list(
      iv_repository_id = 'issue-label-repository'
      iv_issue_id = 'issue-1' ) ) = 1.
  ENDMETHOD.

ENDCLASS.
