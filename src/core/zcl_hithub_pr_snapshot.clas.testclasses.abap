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

    ASSERT zcl_hithub_pr_snapshot=>open( ls_snapshot ) = abap_true.
    ASSERT zcl_hithub_pr_snapshot=>open( ls_snapshot ) = abap_false.
    DATA(ls_read) = zcl_hithub_pr_snapshot=>read(
      iv_repository_id = ls_snapshot-repository_id iv_id = ls_snapshot-id ).
    ASSERT ls_read-base_oid = 'a'.
    ASSERT ls_read-head_oid = 'b'.
    ASSERT ls_read-version = 1.
  ENDMETHOD.

  METHOD rejects_incomplete_snapshot.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-invalid-1'.
    ls_snapshot-id = 'pull-request-invalid-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_open.
    ASSERT zcl_hithub_pr_snapshot=>open( ls_snapshot ) = abap_false.
  ENDMETHOD.

ENDCLASS.
