CLASS zcl_hithub_branch_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS one
      IMPORTING
        is_reference TYPE zif_hithub_metadata_store=>ty_reference
      RETURNING VALUE(rv_body) TYPE xstring.
    CLASS-METHODS list
      IMPORTING
        it_references TYPE zif_hithub_metadata_store=>ty_references
      RETURNING VALUE(rv_body) TYPE xstring.
  PRIVATE SECTION.
    CLASS-METHODS members
      IMPORTING
        is_reference TYPE zif_hithub_metadata_store=>ty_reference
      RETURNING VALUE(rt_members) TYPE zcl_hithub_json=>ty_members.
ENDCLASS.

CLASS zcl_hithub_branch_repr IMPLEMENTATION.

  METHOD members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_version TYPE string.
    ls_member-name = 'name'.
    ls_member-kind = 'string'.
    ls_member-value = is_reference-name.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'algorithm'.
    ls_member-kind = 'string'.
    ls_member-value = is_reference-algorithm.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'oid'.
    ls_member-kind = 'string'.
    ls_member-value = is_reference-oid.
    APPEND ls_member TO rt_members.
    CLEAR ls_member.
    ls_member-name = 'version'.
    ls_member-kind = 'number'.
    lv_version = |{ is_reference-version }|.
    ls_member-value = lv_version.
    APPEND ls_member TO rt_members.
  ENDMETHOD.

  METHOD one.
    rv_body = zcl_hithub_json=>serialize_data( members( is_reference ) ).
  ENDMETHOD.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    lv_json = '['.
    LOOP AT it_references INTO ls_reference.
      IF sy-tabix > 1.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize(
        members( ls_reference ) ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
