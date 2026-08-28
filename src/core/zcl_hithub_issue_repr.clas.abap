CLASS zcl_hithub_issue_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS members
      IMPORTING
        is_issue TYPE zcl_hithub_issues=>ty_issue
      RETURNING
        VALUE(rt_members) TYPE zcl_hithub_json=>ty_members.

    CLASS-METHODS one
      IMPORTING
        is_issue TYPE zcl_hithub_issues=>ty_issue
      RETURNING
        VALUE(rv_body) TYPE xstring.

    CLASS-METHODS list
      IMPORTING
        it_issues TYPE zcl_hithub_issues=>ty_issues
      RETURNING
        VALUE(rv_body) TYPE xstring.
ENDCLASS.

CLASS zcl_hithub_issue_repr IMPLEMENTATION.

  METHOD members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_version TYPE string.

    CLEAR rt_members.
    ls_member-name = 'id'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-id.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'title'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-title.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'body'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-body.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'state'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-state.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'actor'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-actor.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'created_at'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-created_at.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'updated_at'.
    ls_member-kind = 'string'.
    ls_member-value = is_issue-updated_at.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'version'.
    ls_member-kind = 'number'.
    lv_version = |{ is_issue-version }|.
    ls_member-value = lv_version.
    APPEND ls_member TO rt_members.
  ENDMETHOD.

  METHOD one.
    rv_body = zcl_hithub_json=>serialize_data( members( is_issue ) ).
  ENDMETHOD.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.

    lv_json = '['.
    LOOP AT it_issues INTO ls_issue.
      IF sy-tabix > 1.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize(
        members( ls_issue ) ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
