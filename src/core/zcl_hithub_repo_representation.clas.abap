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
    CLASS-METHODS one_with_readme
      IMPORTING
        is_repository TYPE zif_hithub_metadata_store=>ty_repository
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_objects TYPE REF TO zif_hithub_object_store
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

  METHOD one_with_readme.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_commit_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_commit_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_tree_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_tree_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_tree_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_tree_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_blob_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_blob_object TYPE zif_hithub_object_store=>ty_object.
    DATA lo_input TYPE REF TO cl_abap_conv_in_ce.
    DATA lv_readme TYPE string.

    lt_members = members( is_repository ).
    TRY.
        IF io_metadata IS INITIAL OR io_objects IS INITIAL.
          rv_body = zcl_hithub_json=>serialize_data( lt_members ).
          RETURN.
        ENDIF.
        ls_reference = io_metadata->read_reference(
          iv_repository_id = is_repository-id
          iv_name = is_repository-default_branch ).
        IF ls_reference-oid IS INITIAL.
          rv_body = zcl_hithub_json=>serialize_data( lt_members ).
          RETURN.
        ENDIF.
        ls_commit_key-repository_id = is_repository-id.
        ls_commit_key-algorithm = ls_reference-algorithm.
        ls_commit_key-oid = ls_reference-oid.
        ls_commit_object = io_objects->read( ls_commit_key ).
        ls_commit = zcl_hithub_commit_codec=>decode(
          ls_commit_object-payload ).
        ls_tree_key-repository_id = is_repository-id.
        ls_tree_key-algorithm = ls_reference-algorithm.
        ls_tree_key-oid = ls_commit-tree.
        ls_tree_object = io_objects->read( ls_tree_key ).
        lt_tree_entries = zcl_hithub_tree_codec=>decode(
          ls_tree_object-payload ).
        LOOP AT lt_tree_entries INTO ls_tree_entry.
          IF ls_tree_entry-name = 'README.md'.
            ls_blob_key-repository_id = is_repository-id.
            ls_blob_key-algorithm = ls_reference-algorithm.
            ls_blob_key-oid = CONV string( ls_tree_entry-oid ).
            ls_blob_object = io_objects->read( ls_blob_key ).
            lo_input = cl_abap_conv_in_ce=>create(
              input = ls_blob_object-payload encoding = 'UTF-8' ).
            lo_input->read( IMPORTING data = lv_readme ).
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lv_readme IS NOT INITIAL.
          CLEAR ls_member.
          ls_member-name = 'readme'.
          ls_member-kind = 'string'.
          ls_member-value = lv_readme.
          APPEND ls_member TO lt_members.
        ENDIF.
      CATCH cx_root.
        CLEAR lv_readme.
    ENDTRY.
    rv_body = zcl_hithub_json=>serialize_data( lt_members ).
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
