CLASS ltcl_squash_merge DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS creates_single_parent_commit FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_squash_merge IMPLEMENTATION.

  METHOD creates_single_parent_commit.
    DATA ls_result TYPE zcl_hithub_squash_merge=>ty_result.
    ls_result = zcl_hithub_squash_merge=>create(
      iv_tree_oid = 'tree' iv_target_oid = 'target'
      iv_expected_head_oid = 'source' iv_current_head_oid = 'source'
      iv_author = 'Maintainer <maintainer@example.test> 0 +0000'
      iv_committer = 'Maintainer <maintainer@example.test> 0 +0000'
      iv_message = 'Squashed pull request' iv_clean = abap_true ).
    ASSERT ls_result-success = abap_true.
    ASSERT lines( ls_result-commit-parents ) = 1.
    ASSERT ls_result-commit-parents[ 1 ] = 'target'.
    ASSERT ls_result-oid IS NOT INITIAL.
  ENDMETHOD.

ENDCLASS.
