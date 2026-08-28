CLASS ltcl_merge_result DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS persists_result_for_retry FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_result IMPLEMENTATION.

  METHOD persists_result_for_retry.
    DATA ls_result TYPE zcl_hithub_merge_result=>ty_result.
    DATA ls_read TYPE zcl_hithub_merge_result=>ty_result.
    ls_result-repository_id = 'merge-result-repository-1'.
    ls_result-pull_request_id = 'pull-request-1'.
    ls_result-merge_id = 'merge-1'.
    ls_result-commit_oid = 'commit-1'.
    ls_result-created_at = '2026-08-28T12:00:00Z'.

    ASSERT zcl_hithub_merge_result=>save( ls_result ) = abap_true.
    ASSERT zcl_hithub_merge_result=>save( ls_result ) = abap_false.
    ls_read = zcl_hithub_merge_result=>read(
      iv_repository_id = ls_result-repository_id
      iv_pull_request_id = ls_result-pull_request_id ).
    ASSERT ls_read-merge_id = 'merge-1'.
    ASSERT ls_read-commit_oid = 'commit-1'.
  ENDMETHOD.

ENDCLASS.
