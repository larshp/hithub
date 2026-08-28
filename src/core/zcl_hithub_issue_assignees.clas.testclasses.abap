CLASS ltcl_issue_assignees DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS manages_free_form_actors FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_issue_assignees IMPLEMENTATION.

  METHOD manages_free_form_actors.
    ASSERT zcl_hithub_issue_assignees=>add(
      iv_repository_id = 'issue-assignee-repository'
      iv_issue_id = 'issue-1' iv_actor = 'z-team' ) = abap_true.
    ASSERT zcl_hithub_issue_assignees=>add(
      iv_repository_id = 'issue-assignee-repository'
      iv_issue_id = 'issue-1' iv_actor = 'Alice <alice@example.test>' ) =
      abap_true.
    ASSERT zcl_hithub_issue_assignees=>add(
      iv_repository_id = 'issue-assignee-repository'
      iv_issue_id = 'issue-1' iv_actor = 'z-team' ) = abap_false.
    DATA(lt_assignees) = zcl_hithub_issue_assignees=>list(
      iv_repository_id = 'issue-assignee-repository' iv_issue_id = 'issue-1' ).
    ASSERT lines( lt_assignees ) = 2.
    ASSERT lt_assignees[ 1 ] = 'Alice <alice@example.test>'.
    ASSERT zcl_hithub_issue_assignees=>remove(
      iv_repository_id = 'issue-assignee-repository'
      iv_issue_id = 'issue-1' iv_actor = 'z-team' ) = abap_true.
    ASSERT lines( zcl_hithub_issue_assignees=>list(
      iv_repository_id = 'issue-assignee-repository'
      iv_issue_id = 'issue-1' ) ) = 1.
  ENDMETHOD.

ENDCLASS.
