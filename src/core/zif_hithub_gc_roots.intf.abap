INTERFACE zif_hithub_gc_roots
  PUBLIC.

  TYPES ty_keys TYPE STANDARD TABLE OF zif_hithub_object_store=>ty_object_key
    WITH DEFAULT KEY.

  METHODS list
    IMPORTING
      iv_repository_id TYPE string
    RETURNING
      VALUE(rt_keys)   TYPE ty_keys.

ENDINTERFACE.
