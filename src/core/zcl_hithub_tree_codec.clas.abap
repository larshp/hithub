CLASS zcl_hithub_tree_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        mode TYPE string,
        name TYPE string,
        oid  TYPE xstring,
      END OF ty_entry,
      ty_entries TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    CLASS-METHODS encode
      IMPORTING
        it_entries TYPE ty_entries
      RETURNING
        VALUE(rv_payload) TYPE xstring
      RAISING
        cx_static_check.

    CLASS-METHODS decode
      IMPORTING
        iv_payload TYPE xstring
        iv_oid_length TYPE i DEFAULT 20
      RETURNING
        VALUE(rt_entries) TYPE ty_entries
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_tree_codec IMPLEMENTATION.

  METHOD encode.
    DATA lo_out TYPE REF TO cl_abap_conv_out_ce.
    DATA lv_prefix TYPE xstring.
    DATA lv_zero TYPE x LENGTH 1.

    CLEAR rv_payload.
    LOOP AT it_entries INTO DATA(ls_entry).
      lo_out = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
      lo_out->write( data = |{ ls_entry-mode } { ls_entry-name }| ).
      lv_prefix = lo_out->get_buffer( ).
      CONCATENATE rv_payload lv_prefix lv_zero ls_entry-oid
        INTO rv_payload IN BYTE MODE.
    ENDLOOP.
  ENDMETHOD.

  METHOD decode.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_name_end TYPE i.
    DATA lv_prefix_length TYPE i.
    DATA lv_oid_offset TYPE i.
    DATA lv_prefix TYPE xstring.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_zero TYPE x LENGTH 1.
    DATA lv_text TYPE string.
    DATA lo_in TYPE REF TO cl_abap_conv_in_ce.
    DATA ls_entry TYPE ty_entry.

    CLEAR rt_entries.
    IF iv_oid_length <= 0.
      RETURN.
    ENDIF.
    lv_length = xstrlen( iv_payload ).
    lv_offset = 0.

    WHILE lv_offset < lv_length.
      lv_name_end = lv_offset.
      WHILE lv_name_end < lv_length.
        lv_byte = iv_payload+lv_name_end(1).
        IF lv_byte = lv_zero.
          EXIT.
        ENDIF.
        lv_name_end = lv_name_end + 1.
      ENDWHILE.
      IF lv_name_end >= lv_length.
        CLEAR rt_entries.
        RETURN.
      ENDIF.

      lv_prefix_length = lv_name_end - lv_offset.
      lv_prefix = iv_payload+lv_offset(lv_prefix_length).
      lo_in = cl_abap_conv_in_ce=>create( input = lv_prefix encoding = 'UTF-8' ).
      CLEAR lv_text.
      lo_in->read( IMPORTING data = lv_text ).
      CLEAR ls_entry.
      SPLIT lv_text AT space INTO ls_entry-mode ls_entry-name.
      IF ls_entry-mode IS INITIAL OR ls_entry-name IS INITIAL.
        CLEAR rt_entries.
        RETURN.
      ENDIF.

      lv_oid_offset = lv_name_end + 1.
      IF lv_oid_offset + iv_oid_length > lv_length.
        CLEAR rt_entries.
        RETURN.
      ENDIF.
      ls_entry-oid = iv_payload+lv_oid_offset(iv_oid_length).
      APPEND ls_entry TO rt_entries.
      lv_offset = lv_oid_offset + iv_oid_length.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
