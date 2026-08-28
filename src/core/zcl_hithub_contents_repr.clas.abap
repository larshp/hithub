CLASS zcl_hithub_contents_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS list
      IMPORTING
        it_entries TYPE zcl_hithub_contents_service=>ty_entries
      RETURNING
        VALUE(rv_body) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_contents_repr IMPLEMENTATION.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_entry TYPE zcl_hithub_contents_service=>ty_entry.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_size TYPE string.

    lv_json = '{"entries":['.
    LOOP AT it_entries INTO ls_entry.
      CLEAR lt_members.
      APPEND VALUE #( name = 'name' kind = 'string'
        value = ls_entry-name ) TO lt_members.
      APPEND VALUE #( name = 'type' kind = 'string'
        value = ls_entry-type ) TO lt_members.
      APPEND VALUE #( name = 'mode' kind = 'string'
        value = ls_entry-mode ) TO lt_members.
      APPEND VALUE #( name = 'algorithm' kind = 'string'
        value = ls_entry-algorithm ) TO lt_members.
      APPEND VALUE #( name = 'oid' kind = 'string'
        value = ls_entry-oid ) TO lt_members.
      IF ls_entry-type = 'blob'.
        lv_size = |{ ls_entry-size }|.
        APPEND VALUE #( name = 'size' kind = 'number'
          value = lv_size ) TO lt_members.
      ENDIF.
      IF lv_json <> '{"entries":['.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize( lt_members ).
    ENDLOOP.
    lv_json = lv_json && ']}'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
