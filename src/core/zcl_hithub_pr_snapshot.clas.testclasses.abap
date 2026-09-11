CLASS ltcl_pull_request_snapshot DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_immutable_tips FOR TESTING RAISING cx_static_check.
    METHODS rejects_incomplete_snapshot FOR TESTING RAISING cx_static_check.
    METHODS derives_title_from_refs FOR TESTING RAISING cx_static_check.
    METHODS keeps_supplied_description FOR TESTING RAISING cx_static_check.
    METHODS truncates_derived_title FOR TESTING RAISING cx_static_check.
    METHODS rejects_overlong_title FOR TESTING RAISING cx_static_check.
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

  METHOD derives_title_from_refs.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-repository-2'.
    ls_snapshot-id = 'pull-request-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_draft.
    ls_snapshot-source_ref = 'refs/heads/feature'.
    ls_snapshot-target_ref = 'refs/heads/main'.
    ls_snapshot-base_oid = 'a'.
    ls_snapshot-head_oid = 'b'.
    ls_snapshot-actor = 'author'.

    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pr_snapshot=>open( ls_snapshot ) ).
    DATA(ls_read) = zcl_hithub_pr_snapshot=>read(
      iv_repository_id = ls_snapshot-repository_id iv_id = ls_snapshot-id ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-title exp = 'feature into main' ).
    cl_abap_unit_assert=>assert_equals( act = ls_read-actor exp = 'author' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_read-created_at ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-updated_at exp = ls_read-created_at ).
  ENDMETHOD.

  METHOD keeps_supplied_description.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-repository-3'.
    ls_snapshot-id = 'pull-request-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_draft.
    ls_snapshot-source_ref = 'refs/heads/feature'.
    ls_snapshot-target_ref = 'refs/heads/main'.
    ls_snapshot-base_oid = 'a'.
    ls_snapshot-head_oid = 'b'.
    ls_snapshot-title = 'Rename the helper'.
    ls_snapshot-body = 'The old name said nothing about what it returns.'.

    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pr_snapshot=>open( ls_snapshot ) ).
    DATA(ls_read) = zcl_hithub_pr_snapshot=>read(
      iv_repository_id = ls_snapshot-repository_id iv_id = ls_snapshot-id ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-title exp = 'Rename the helper' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-body
      exp = 'The old name said nothing about what it returns.' ).
  ENDMETHOD.

  METHOD truncates_derived_title.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-repository-4'.
    ls_snapshot-id = 'pull-request-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_draft.
    ls_snapshot-source_ref = |refs/heads/{ repeat( val = 'a' occ = 149 ) }|.
    ls_snapshot-target_ref = |refs/heads/{ repeat( val = 'b' occ = 149 ) }|.
    ls_snapshot-base_oid = 'a'.
    ls_snapshot-head_oid = 'b'.

    DATA(ls_normalized) = zcl_hithub_pr_snapshot=>normalize( ls_snapshot ).
    cl_abap_unit_assert=>assert_equals(
      act = strlen( ls_normalized-title )
      exp = zcl_hithub_pr_snapshot=>c_title_length ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pr_snapshot=>is_valid( ls_normalized ) ).
  ENDMETHOD.

  METHOD rejects_overlong_title.
    DATA ls_snapshot TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    ls_snapshot-repository_id = 'snapshot-repository-5'.
    ls_snapshot-id = 'pull-request-1'.
    ls_snapshot-state = zcl_hithub_pull_request_state=>c_draft.
    ls_snapshot-source_ref = 'refs/heads/feature'.
    ls_snapshot-target_ref = 'refs/heads/main'.
    ls_snapshot-base_oid = 'a'.
    ls_snapshot-head_oid = 'b'.
    ls_snapshot-title = repeat( val = 'x' occ = 256 ).

    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pr_snapshot=>is_valid( ls_snapshot ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pr_snapshot=>open( ls_snapshot ) ).
  ENDMETHOD.

ENDCLASS.
