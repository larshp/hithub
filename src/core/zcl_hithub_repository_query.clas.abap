CLASS zcl_hithub_repository_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store.
    METHODS list
      RETURNING
        VALUE(rt_repositories) TYPE zif_hithub_metadata_store=>ty_repositories
      RAISING
        cx_static_check.
    METHODS find
      IMPORTING
        iv_name              TYPE string
        iv_include_deleted   TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rs_repository) TYPE zif_hithub_metadata_store=>ty_repository
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.

ENDCLASS.

CLASS zcl_hithub_repository_query IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
  ENDMETHOD.

  METHOD list.
    IF mo_metadata IS INITIAL.
      RETURN.
    ENDIF.
    rt_repositories = mo_metadata->list_repositories( ).
  ENDMETHOD.

  METHOD find.
    DATA lt_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA lv_name TYPE string.
    DATA lv_candidate TYPE string.

    CLEAR rs_repository.
    IF mo_metadata IS INITIAL OR iv_name IS INITIAL.
      RETURN.
    ENDIF.
    lv_name = iv_name.
    TRANSLATE lv_name TO LOWER CASE.
    lt_repositories = mo_metadata->list_repositories(
      iv_include_deleted = iv_include_deleted ).
    LOOP AT lt_repositories INTO ls_repository.
      lv_candidate = ls_repository-name.
      TRANSLATE lv_candidate TO LOWER CASE.
      IF lv_candidate = lv_name.
        rs_repository = ls_repository.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
