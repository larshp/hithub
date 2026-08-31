CLASS ltcl_repository_representation DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS serializes_one_repository FOR TESTING RAISING cx_static_check.
    METHODS serializes_repository_list FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_repository_representation IMPLEMENTATION.

  METHOD serializes_one_repository.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'representation-repository-000000'.
    ls_repository-name = 'representation-repo'.
    ls_repository-description = 'safe \" description'.
    ls_repository-default_branch = 'refs/heads/main'.
    ls_repository-version = 3.

    DATA(ls_document) = zcl_hithub_json=>parse_data(
      zcl_hithub_repo_representation=>one( ls_repository ) ).
    ASSERT ls_document-valid = abap_true.
    ASSERT lines( ls_document-members ) = 5.
  ENDMETHOD.

  METHOD serializes_repository_list.
    DATA lt_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'representation-list-00000000000000000'.
    ls_repository-name = 'first-repository'.
    ls_repository-version = 1.
    APPEND ls_repository TO lt_repositories.
    CLEAR ls_repository.
    ls_repository-id = 'representation-list-00000000000000001'.
    ls_repository-name = 'second-repository'.
    ls_repository-version = 1.
    APPEND ls_repository TO lt_repositories.

    DATA(lv_body) = zcl_hithub_repo_representation=>list(
      lt_repositories ).
    DATA(lv_json) = cl_abap_codepage=>convert_from( lv_body ).
    DATA(lv_last_offset) = strlen( lv_json ) - 1.
    ASSERT lv_json(1) = '['.
    ASSERT lv_json+lv_last_offset(1) = ']'.
    ASSERT lv_json CS 'first-repository'.
    ASSERT lv_json CS 'second-repository'.
  ENDMETHOD.

ENDCLASS.
