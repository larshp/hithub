CLASS ltcl_pull_request_snapshot DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_immutable_tips FOR TESTING RAISING cx_static_check.
    METHODS rejects_incomplete_snapshot FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pull_request_snapshot IMPLEMENTATION.

  METHOD writes_immutable_tips.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-repository-1'.
    ls_snapshot-id = 'pull-request-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_draft.
    ls_snapshot-source_ref = 'refs/heads/feature'.
    ls_snapshot-target_ref = 'refs/heads/main'.
    ls_snapshot-base_oid = 'a'.
    ls_snapshot-head_oid = 'b'.

    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pr_snapshot=>open( ls_snapshot ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pr_snapshot=>open( ls_snapshot ) ).
    DATA(ls_read) = zcl_hithub_pr_snapshot=>read(
      iv_repository_id = ls_snapshot-repository_id iv_id = ls_snapshot-id ).
    cl_abap_unit_assert=>assert_equals( act = ls_read-base_oid exp = 'a' ).
    cl_abap_unit_assert=>assert_equals( act = ls_read-head_oid exp = 'b' ).
    cl_abap_unit_assert=>assert_equals( act = ls_read-version exp = 1 ).
  ENDMETHOD.

  METHOD rejects_incomplete_snapshot.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-invalid-1'.
    ls_snapshot-id = 'pull-request-invalid-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_open.
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pr_snapshot=>open( ls_snapshot ) ).
  ENDMETHOD.

ENDCLASS.
