INTERFACE zif_hithub_quarantine
  PUBLIC.

  TYPES ty_objects TYPE STANDARD TABLE OF zif_hithub_object_store=>ty_object
    WITH DEFAULT KEY.

  METHODS stage
    IMPORTING
      it_objects TYPE ty_objects
    RETURNING
      VALUE(rv_staged) TYPE i.

  METHODS promote
    RETURNING
      VALUE(rv_promoted) TYPE i
    RAISING
      cx_static_check.

  METHODS discard.

  METHODS count
    RETURNING
      VALUE(rv_count) TYPE i.

ENDINTERFACE.
