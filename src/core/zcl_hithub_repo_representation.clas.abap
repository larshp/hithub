CLASS zcl_hithub_repo_representation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS members
      IMPORTING
        is_repository TYPE zif_hithub_metadata_store=>ty_repository
      RETURNING
        VALUE(rt_members) TYPE zcl_hithub_json=>ty_members.
    CLASS-METHODS one
      IMPORTING
        is_repository TYPE zif_hithub_metadata_store=>ty_repository
      RETURNING
        VALUE(rv_body) TYPE xstring.
    CLASS-METHODS list
      IMPORTING
        it_repositories TYPE zif_hithub_metadata_store=>ty_repositories
      RETURNING
        VALUE(rv_body) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_repo_representation IMPLEMENTATION.

  METHOD members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_version TYPE string.

    CLEAR rt_members.
    ls_member-name = 'id'.
    ls_member-kind = 'string'.
    ls_member-value = is_repository-id.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'name'.
    ls_member-kind = 'string'.
    ls_member-value = is_repository-name.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'description'.
    ls_member-kind = 'string'.
    ls_member-value = is_repository-description.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'default_branch'.
    ls_member-kind = 'string'.
    ls_member-value = is_repository-default_branch.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'version'.
    ls_member-kind = 'number'.
    lv_version = |{ is_repository-version }|.
    ls_member-value = lv_version.
    APPEND ls_member TO rt_members.
  ENDMETHOD.

  METHOD one.
    rv_body = zcl_hithub_json=>serialize_data(
      members( is_repository ) ).
  ENDMETHOD.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.

    lv_json = '['.
    LOOP AT it_repositories INTO ls_repository.
      IF sy-tabix > 1.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize(
        members( ls_repository ) ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
