CLASS zcl_hithub_pack_ingestor DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_objects TYPE STANDARD TABLE OF zif_hithub_object_store=>ty_object
      WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        io_store TYPE REF TO zif_hithub_object_store.

    METHODS ingest
      IMPORTING
        it_objects        TYPE ty_objects
      RETURNING
        VALUE(rv_created) TYPE i
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_writer TYPE REF TO zcl_hithub_object_writer.

ENDCLASS.

CLASS zcl_hithub_pack_ingestor IMPLEMENTATION.

  METHOD constructor.
    mo_writer = NEW zcl_hithub_object_writer( io_store ).
  ENDMETHOD.

  METHOD ingest.
    CLEAR rv_created.
    IF mo_writer IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT it_objects INTO DATA(ls_object).
      IF mo_writer->write( ls_object ) = abap_true.
        rv_created = rv_created + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
