CLASS zcl_hithub_pack_index DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        oid    TYPE string,
        offset TYPE i,
      END OF ty_entry,
      ty_entries TYPE SORTED TABLE OF ty_entry WITH UNIQUE KEY oid.

    METHODS add
      IMPORTING
        iv_oid    TYPE string
        iv_offset TYPE i
      RETURNING
        VALUE(rv_added) TYPE abap_bool.

    METHODS find
      IMPORTING
        iv_oid TYPE string
      RETURNING
        VALUE(rv_offset) TYPE i.

    METHODS all
      RETURNING
        VALUE(rt_entries) TYPE ty_entries.

  PRIVATE SECTION.
    DATA mt_entries TYPE ty_entries.

ENDCLASS.

CLASS zcl_hithub_pack_index IMPLEMENTATION.

  METHOD add.
    DATA ls_entry TYPE ty_entry.

    CLEAR rv_added.
    IF iv_oid IS INITIAL OR iv_offset < 0.
      RETURN.
    ENDIF.
    ls_entry-oid = iv_oid.
    ls_entry-offset = iv_offset.
    INSERT ls_entry INTO TABLE mt_entries.
    IF sy-subrc = 0.
      rv_added = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD find.
    READ TABLE mt_entries INTO DATA(ls_entry) WITH TABLE KEY oid = iv_oid.
    IF sy-subrc = 0.
      rv_offset = ls_entry-offset.
    ENDIF.
  ENDMETHOD.

  METHOD all.
    rt_entries = mt_entries.
  ENDMETHOD.

ENDCLASS.
