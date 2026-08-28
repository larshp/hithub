CLASS zcl_hithub_merge_result DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        repository_id   TYPE string,
        pull_request_id TYPE string,
        merge_id        TYPE string,
        commit_oid      TYPE string,
        created_at      TYPE string,
      END OF ty_result.

    CLASS-METHODS save
      IMPORTING
        is_result TYPE ty_result
      RETURNING
        VALUE(rv_saved) TYPE abap_bool.

    CLASS-METHODS read
      IMPORTING
        iv_repository_id TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.
ENDCLASS.

CLASS zcl_hithub_merge_result IMPLEMENTATION.

  METHOD save.
    DATA ls_row TYPE zhi_pr_merge_result.
    DATA ls_existing TYPE zhi_pr_merge_result.

    CLEAR rv_saved.
    IF is_result-repository_id IS INITIAL
        OR is_result-pull_request_id IS INITIAL
        OR is_result-merge_id IS INITIAL OR is_result-commit_oid IS INITIAL
        OR is_result-created_at IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_pr_merge_result INTO @ls_existing
      WHERE repository_id = @is_result-repository_id
        AND pull_request_id = @is_result-pull_request_id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = is_result-repository_id.
    ls_row-pull_request_id = is_result-pull_request_id.
    ls_row-merge_id = is_result-merge_id.
    ls_row-commit_oid = is_result-commit_oid.
    ls_row-created_at = is_result-created_at.
    INSERT zhi_pr_merge_result FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD read.
    DATA ls_row TYPE zhi_pr_merge_result.

    CLEAR rs_result.
    SELECT SINGLE * FROM zhi_pr_merge_result INTO @ls_row
      WHERE repository_id = @iv_repository_id
        AND pull_request_id = @iv_pull_request_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    rs_result-repository_id = ls_row-repository_id.
    rs_result-pull_request_id = ls_row-pull_request_id.
    rs_result-merge_id = ls_row-merge_id.
    rs_result-commit_oid = ls_row-commit_oid.
    rs_result-created_at = ls_row-created_at.
  ENDMETHOD.

ENDCLASS.
