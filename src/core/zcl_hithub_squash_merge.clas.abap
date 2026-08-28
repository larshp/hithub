CLASS zcl_hithub_squash_merge DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        success TYPE abap_bool,
        reason  TYPE string,
        oid     TYPE string,
        commit  TYPE zcl_hithub_commit_codec=>ty_commit,
      END OF ty_result.

    CLASS-METHODS create
      IMPORTING
        iv_tree_oid TYPE string
        iv_target_oid TYPE string
        iv_expected_head_oid TYPE string
        iv_current_head_oid TYPE string
        iv_author TYPE string
        iv_committer TYPE string
        iv_message TYPE string
        iv_clean TYPE abap_bool
      RETURNING
        VALUE(rs_result) TYPE ty_result
      RAISING
        cx_static_check.
ENDCLASS.

CLASS zcl_hithub_squash_merge IMPLEMENTATION.

  METHOD create.
    CLEAR rs_result.
    IF iv_clean = abap_false.
      rs_result-reason = 'cannot squash a conflicting merge'.
      RETURN.
    ENDIF.
    IF iv_expected_head_oid IS INITIAL OR iv_current_head_oid IS INITIAL
        OR iv_expected_head_oid <> iv_current_head_oid.
      rs_result-reason = 'merge request head is stale'.
      RETURN.
    ENDIF.
    IF iv_tree_oid IS INITIAL OR iv_target_oid IS INITIAL
        OR iv_author IS INITIAL OR iv_committer IS INITIAL
        OR iv_message IS INITIAL.
      rs_result-reason = 'squash commit input is incomplete'.
      RETURN.
    ENDIF.
    IF zcl_hithub_identity=>is_valid( iv_author ) = abap_false
        OR zcl_hithub_identity=>is_valid( iv_committer ) = abap_false.
      rs_result-reason = 'squash commit identity is invalid'.
      RETURN.
    ENDIF.
    rs_result-commit-tree = iv_tree_oid.
    APPEND iv_target_oid TO rs_result-commit-parents.
    rs_result-commit-author = iv_author.
    rs_result-commit-committer = iv_committer.
    rs_result-commit-message = iv_message.
    DATA(lv_payload) = zcl_hithub_commit_codec=>encode( rs_result-commit ).
    rs_result-oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_payload ).
    rs_result-success = abap_true.
  ENDMETHOD.

ENDCLASS.
