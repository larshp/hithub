INTERFACE zif_hithub_object_store
  PUBLIC.

  TYPES:
    BEGIN OF ty_object_key,
      repository_id TYPE string,
      algorithm     TYPE string,
      oid           TYPE string,
    END OF ty_object_key,
    BEGIN OF ty_object,
      key        TYPE ty_object_key,
      type       TYPE string,
      size       TYPE int8,
      created_at TYPE timestampl,
      payload    TYPE xstring,
    END OF ty_object.

  METHODS read
    IMPORTING
      is_key           TYPE ty_object_key
    RETURNING
      VALUE(rs_object) TYPE ty_object
    RAISING
      cx_static_check.

  METHODS contains
    IMPORTING
      is_key           TYPE ty_object_key
    RETURNING
      VALUE(rv_exists) TYPE abap_bool.

  METHODS write
    IMPORTING
      is_object         TYPE ty_object
    RETURNING
      VALUE(rv_created) TYPE abap_bool
    RAISING
      cx_static_check.

  METHODS purge_repository
    IMPORTING
      iv_repository_id TYPE string
    RETURNING
      VALUE(rv_purged) TYPE abap_bool
    RAISING
      cx_static_check.

ENDINTERFACE.
