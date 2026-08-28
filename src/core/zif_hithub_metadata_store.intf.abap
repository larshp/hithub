INTERFACE zif_hithub_metadata_store
  PUBLIC.

  TYPES:
    BEGIN OF ty_repository,
      id             TYPE string,
      name           TYPE string,
      description    TYPE string,
      default_branch TYPE string,
      version        TYPE int8,
      deleted        TYPE abap_bool,
    END OF ty_repository,
    ty_repositories TYPE STANDARD TABLE OF ty_repository WITH DEFAULT KEY,
    BEGIN OF ty_reference,
      repository_id  TYPE string,
      name           TYPE string,
      algorithm      TYPE string,
      oid            TYPE string,
      symbolic_target TYPE string,
      version        TYPE int8,
    END OF ty_reference,
    ty_references TYPE STANDARD TABLE OF ty_reference WITH DEFAULT KEY.

  METHODS read_repository
    IMPORTING
      iv_id TYPE string
    RETURNING
      VALUE(rs_repository) TYPE ty_repository
    RAISING
      cx_static_check.

  METHODS read_repository_any
    IMPORTING
      iv_id TYPE string
    RETURNING
      VALUE(rs_repository) TYPE ty_repository
    RAISING
      cx_static_check.

  METHODS list_repositories
    IMPORTING
      iv_include_deleted TYPE abap_bool OPTIONAL
    RETURNING
      VALUE(rt_repositories) TYPE ty_repositories
    RAISING
      cx_static_check.

  METHODS save_repository
    IMPORTING
      is_repository TYPE ty_repository
    RAISING
      cx_static_check.

  METHODS update_repository
    IMPORTING
      is_repository       TYPE ty_repository
      iv_expected_version TYPE int8
    RETURNING
      VALUE(rv_version) TYPE int8
    RAISING
      cx_static_check.

  METHODS purge_repository
    IMPORTING
      iv_repository_id   TYPE string
      iv_expected_version TYPE int8
    RETURNING
      VALUE(rv_purged) TYPE abap_bool
    RAISING
      cx_static_check.

  METHODS read_idempotency
    IMPORTING
      iv_actor TYPE string
      iv_key TYPE string
    RETURNING
      VALUE(rv_subject_id) TYPE string
    RAISING
      cx_static_check.

  METHODS save_idempotency
    IMPORTING
      iv_actor TYPE string
      iv_key TYPE string
      iv_subject_id TYPE string
    RETURNING
      VALUE(rv_saved) TYPE abap_bool
    RAISING
      cx_static_check.

  METHODS list_references
    IMPORTING
      iv_repository_id TYPE string
    RETURNING
      VALUE(rt_references) TYPE ty_references
    RAISING
      cx_static_check.

  METHODS read_reference
    IMPORTING
      iv_repository_id TYPE string
      iv_name          TYPE string
    RETURNING
      VALUE(rs_reference) TYPE ty_reference
    RAISING
      cx_static_check.

  METHODS save_reference
    IMPORTING
      is_reference        TYPE ty_reference
      iv_expected_version  TYPE int8 OPTIONAL
    RETURNING
      VALUE(rv_version) TYPE int8
    RAISING
      cx_static_check.

  METHODS create_reference
    IMPORTING
      is_reference TYPE ty_reference
    RETURNING
      VALUE(rv_version) TYPE int8
    RAISING
      cx_static_check.

  METHODS delete_reference
    IMPORTING
      iv_repository_id   TYPE string
      iv_name            TYPE string
      iv_expected_version TYPE int8 OPTIONAL
    RAISING
      cx_static_check.

ENDINTERFACE.
