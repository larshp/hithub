CLASS zcl_hithub_object_reader DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_store TYPE REF TO zif_hithub_object_store.

    METHODS read
      IMPORTING
        is_key TYPE zif_hithub_object_store=>ty_object_key
      RETURNING
        VALUE(rs_object) TYPE zif_hithub_object_store=>ty_object
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_store TYPE REF TO zif_hithub_object_store.

ENDCLASS.

CLASS zcl_hithub_object_reader IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
  ENDMETHOD.

  METHOD read.
    IF mo_store IS INITIAL.
      RETURN.
    ENDIF.
    rs_object = mo_store->read( is_key ).
  ENDMETHOD.

ENDCLASS.
