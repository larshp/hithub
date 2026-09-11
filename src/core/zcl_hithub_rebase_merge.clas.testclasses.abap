CLASS ltcl_rebase_merge DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS creates_rebased_commit FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_rebase_merge IMPLEMENTATION.

  METHOD creates_rebased_commit.
    DATA ls_result TYPE zcl_hithub_rebase_merge=>ty_result.
    ls_result = zcl_hithub_rebase_merge=>create(
      iv_tree_oid = 'rebased-tree'
      iv_rebased_parent_oid = 'rebased-target'
      iv_expected_head_oid = 'source' iv_current_head_oid = 'source'
      iv_author = 'Maintainer <maintainer@example.test> 0 +0000'
      iv_committer = 'Maintainer <maintainer@example.test> 0 +0000'
      iv_message = 'Rebased pull request' iv_clean = abap_true ).
    cl_abap_unit_assert=>assert_true( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-commit-parents )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-commit-parents[ 1 ]
      exp = 'rebased-target' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_result-oid ).
  ENDMETHOD.

ENDCLASS.
