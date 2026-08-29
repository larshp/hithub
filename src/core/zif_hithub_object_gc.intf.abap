INTERFACE zif_hithub_object_gc
  PUBLIC.

  TYPES:
    BEGIN OF ty_candidate,
      key        TYPE zif_hithub_object_store=>ty_object_key,
      created_at TYPE timestampl,
    END OF ty_candidate,
    ty_candidates TYPE STANDARD TABLE OF ty_candidate WITH DEFAULT KEY.

  METHODS list
    IMPORTING
      iv_repository_id     TYPE string
    RETURNING
      VALUE(rt_candidates) TYPE ty_candidates
    RAISING cx_static_check.

  METHODS delete
    IMPORTING
      is_key            TYPE zif_hithub_object_store=>ty_object_key
    RETURNING
      VALUE(rv_deleted) TYPE abap_bool
    RAISING cx_static_check.

ENDINTERFACE.
