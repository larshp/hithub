CLASS zcl_hithub_pack_base_resolver DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_reader TYPE REF TO zcl_hithub_object_reader.

    METHODS read
      IMPORTING
        is_key TYPE zif_hithub_object_store=>ty_object_key
      RETURNING
        VALUE(rs_object) TYPE zif_hithub_object_store=>ty_object.

  PRIVATE SECTION.
    DATA mo_reader TYPE REF TO zcl_hithub_object_reader.

ENDCLASS.

CLASS zcl_hithub_pack_base_resolver IMPLEMENTATION.

  METHOD constructor.
    mo_reader = io_reader.
  ENDMETHOD.

  METHOD read.
    CLEAR rs_object.
    IF mo_reader IS INITIAL
        OR is_key-repository_id IS INITIAL
        OR is_key-algorithm IS INITIAL
        OR is_key-oid IS INITIAL.
      RETURN.
    ENDIF.
    rs_object = mo_reader->read( is_key ).
    IF rs_object-key-repository_id <> is_key-repository_id
        OR rs_object-key-algorithm <> is_key-algorithm
        OR rs_object-key-oid <> is_key-oid.
      CLEAR rs_object.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
