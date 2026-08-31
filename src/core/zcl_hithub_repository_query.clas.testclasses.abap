CLASS ltcl_repository_query DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS finds_case_insensitive_name FOR TESTING RAISING cx_static_check.
    METHODS lists_visible_repositories FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_repository_query IMPLEMENTATION.

  METHOD finds_case_insensitive_name.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'query-repository-000000000000000000'.
    ls_repository-name = 'Query-Repo'.
    ls_repository-version = 1.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_query) = NEW zcl_hithub_repository_query( lo_metadata ).

    DATA(ls_found) = lo_query->find( 'QUERY-REPO' ).
    ASSERT ls_found-id = ls_repository-id.
    ASSERT lo_query->find( 'missing-repo' )-id IS INITIAL.
  ENDMETHOD.

  METHOD lists_visible_repositories.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    ls_repository-id = 'query-list-visible-000000000000000'.
    ls_repository-name = 'visible-query-repo'.
    ls_repository-version = 1.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    CLEAR ls_repository.
    ls_repository-id = 'query-list-deleted-000000000000000'.
    ls_repository-name = 'deleted-query-repo'.
    ls_repository-version = 1.
    ls_repository-deleted = abap_true.
    lo_metadata->zif_hithub_metadata_store~save_repository( ls_repository ).
    DATA(lo_query) = NEW zcl_hithub_repository_query( lo_metadata ).

    DATA(lt_repositories) = lo_query->list( ).
    READ TABLE lt_repositories TRANSPORTING NO FIELDS
      WITH KEY name = 'visible-query-repo'.
    ASSERT sy-subrc = 0.
    READ TABLE lt_repositories TRANSPORTING NO FIELDS
      WITH KEY name = 'deleted-query-repo'.
    ASSERT sy-subrc <> 0.
  ENDMETHOD.

ENDCLASS.
