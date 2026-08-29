CLASS ltcl_merge_commit DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS creates_two_parent_commit FOR TESTING RAISING cx_static_check.
    METHODS rejects_conflicting_merge FOR TESTING RAISING cx_static_check.
    METHODS rejects_stale_head FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_identity FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_commit IMPLEMENTATION.

  METHOD creates_two_parent_commit.
    DATA ls_result TYPE zcl_hithub_merge_commit=>ty_result.
    DATA ls_decoded TYPE zcl_hithub_commit_codec=>ty_commit.
    ls_result = zcl_hithub_merge_commit=>create(
      iv_tree_oid          = 'tree-oid'
      iv_target_oid        = 'target-oid'
      iv_source_oid        = 'source-oid'
      iv_expected_head_oid = 'source-oid'
      iv_current_head_oid  = 'source-oid'
      iv_author            = 'Maintainer <maintainer@example.test> 0 +0000'
      iv_committer         = 'Maintainer <maintainer@example.test> 0 +0000'
      iv_message           = 'Merge pull request'
      iv_clean             = abap_true ).
    ASSERT ls_result-success = abap_true.
    ASSERT lines( ls_result-commit-parents ) = 2.
    ASSERT ls_result-commit-parents[ 1 ] = 'target-oid'.
    ASSERT ls_result-commit-parents[ 2 ] = 'source-oid'.
    ASSERT ls_result-oid IS NOT INITIAL.
    ls_decoded = zcl_hithub_commit_codec=>decode( ls_result-payload ).
    ASSERT ls_decoded-tree = 'tree-oid'.
    ASSERT ls_decoded-message = 'Merge pull request'.
  ENDMETHOD.

  METHOD rejects_conflicting_merge.
    DATA ls_result TYPE zcl_hithub_merge_commit=>ty_result.
    ls_result = zcl_hithub_merge_commit=>create(
      iv_tree_oid = 'tree' iv_target_oid = 'target' iv_source_oid = 'source'
      iv_expected_head_oid = 'source' iv_current_head_oid = 'source'
      iv_author = 'author' iv_committer = 'committer'
      iv_message = 'merge' iv_clean = abap_false ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason =
      'cannot create a merge commit for a conflicting merge'.
  ENDMETHOD.

  METHOD rejects_stale_head.
    DATA ls_result TYPE zcl_hithub_merge_commit=>ty_result.
    ls_result = zcl_hithub_merge_commit=>create(
      iv_tree_oid = 'tree' iv_target_oid = 'target' iv_source_oid = 'source'
      iv_expected_head_oid = 'old-source' iv_current_head_oid = 'new-source'
      iv_author = 'author' iv_committer = 'committer'
      iv_message = 'merge' iv_clean = abap_true ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'merge request head is stale'.
  ENDMETHOD.

  METHOD rejects_invalid_identity.
    DATA ls_result TYPE zcl_hithub_merge_commit=>ty_result.
    ls_result = zcl_hithub_merge_commit=>create(
      iv_tree_oid = 'tree' iv_target_oid = 'target' iv_source_oid = 'source'
      iv_expected_head_oid = 'source' iv_current_head_oid = 'source'
      iv_author = 'invalid' iv_committer = 'invalid'
      iv_message = 'merge' iv_clean = abap_true ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'merge commit identity is invalid'.
  ENDMETHOD.

ENDCLASS.
