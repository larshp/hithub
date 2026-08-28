INTERFACE zif_hithub_object_gc
  PUBLIC.

  TYPES ty_keys TYPE STANDARD TABLE OF zif_hithub_object_store=>ty_object_key
    WITH DEFAULT KEY.

  METHODS list
    IMPORTING
      iv_repository_id TYPE string
    RETURNING
      VALUE(rt_keys) TYPE ty_keys
    RAISING cx_static_check.

  METHODS delete
    IMPORTING
      is_key TYPE zif_hithub_object_store=>ty_object_key
    RETURNING
      VALUE(rv_deleted) TYPE abap_bool
    RAISING cx_static_check.

ENDINTERFACE.
