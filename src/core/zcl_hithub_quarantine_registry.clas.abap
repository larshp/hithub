CLASS zcl_hithub_quarantine_registry DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        id            TYPE string,
        quarantine    TYPE REF TO zif_hithub_quarantine,
        last_activity TYPE timestampl,
      END OF ty_entry,
      ty_entries TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    METHODS register
      IMPORTING
        iv_id                TYPE string
        io_quarantine        TYPE REF TO zif_hithub_quarantine
        iv_last_activity     TYPE timestampl
      RETURNING
        VALUE(rv_registered) TYPE abap_bool.

    METHODS cleanup
      IMPORTING
        iv_before         TYPE timestampl
      RETURNING
        VALUE(rv_cleaned) TYPE i.

    METHODS count
      RETURNING
        VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mt_entries TYPE ty_entries.

ENDCLASS.

CLASS zcl_hithub_quarantine_registry IMPLEMENTATION.

  METHOD register.
    DATA ls_entry TYPE ty_entry.

    CLEAR rv_registered.
    IF iv_id IS INITIAL OR io_quarantine IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_entries TRANSPORTING NO FIELDS WITH KEY id = iv_id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_entry-id = iv_id.
    ls_entry-quarantine = io_quarantine.
    ls_entry-last_activity = iv_last_activity.
    APPEND ls_entry TO mt_entries.
    rv_registered = abap_true.
  ENDMETHOD.

  METHOD cleanup.
    DATA ls_entry TYPE ty_entry.

    CLEAR rv_cleaned.
    LOOP AT mt_entries INTO ls_entry.
      IF ls_entry-last_activity < iv_before.
        ls_entry-quarantine->discard( ).
        DELETE mt_entries INDEX sy-tabix.
        rv_cleaned = rv_cleaned + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD count.
    rv_count = lines( mt_entries ).
  ENDMETHOD.

ENDCLASS.
