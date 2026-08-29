CLASS zcl_hithub_pr_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS members
      IMPORTING
        is_pull_request   TYPE zcl_hithub_pr_snapshot=>ty_snapshot
      RETURNING
        VALUE(rt_members) TYPE zcl_hithub_json=>ty_members.

    CLASS-METHODS one
      IMPORTING
        is_pull_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot
      RETURNING
        VALUE(rv_body)  TYPE xstring.

    CLASS-METHODS list
      IMPORTING
        it_pull_requests TYPE zcl_hithub_pr_snapshot=>ty_snapshots
      RETURNING
        VALUE(rv_body)   TYPE xstring.
ENDCLASS.

CLASS zcl_hithub_pr_repr IMPLEMENTATION.

  METHOD members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_version TYPE string.

    CLEAR rt_members.
    ls_member-name = 'id'.
    ls_member-kind = 'string'.
    ls_member-value = is_pull_request-id.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'state'.
    ls_member-kind = 'string'.
    ls_member-value = is_pull_request-state.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'source_ref'.
    ls_member-kind = 'string'.
    ls_member-value = is_pull_request-source_ref.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'target_ref'.
    ls_member-kind = 'string'.
    ls_member-value = is_pull_request-target_ref.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'base_oid'.
    ls_member-kind = 'string'.
    ls_member-value = is_pull_request-base_oid.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'head_oid'.
    ls_member-kind = 'string'.
    ls_member-value = is_pull_request-head_oid.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'version'.
    ls_member-kind = 'number'.
    lv_version = |{ is_pull_request-version }|.
    ls_member-value = lv_version.
    APPEND ls_member TO rt_members.
  ENDMETHOD.

  METHOD one.
    rv_body = zcl_hithub_json=>serialize_data( members( is_pull_request ) ).
  ENDMETHOD.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_pull_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.

    lv_json = '['.
    LOOP AT it_pull_requests INTO ls_pull_request.
      IF sy-tabix > 1.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize(
        members( ls_pull_request ) ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
