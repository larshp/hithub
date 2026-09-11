CLASS zcl_hithub_timeline_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS list
      IMPORTING
        it_entries     TYPE zcl_hithub_timeline=>ty_entries
      RETURNING
        VALUE(rv_body) TYPE xstring.
ENDCLASS.

CLASS zcl_hithub_timeline_repr IMPLEMENTATION.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_entry TYPE zcl_hithub_timeline=>ty_entry.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.

    lv_json = '['.
    LOOP AT it_entries INTO ls_entry.
      CLEAR lt_members.
      APPEND VALUE #( name = 'event_id' kind = 'string'
        value = ls_entry-event_id ) TO lt_members.
      APPEND VALUE #( name = 'actor' kind = 'string'
        value = ls_entry-actor ) TO lt_members.
      APPEND VALUE #( name = 'action' kind = 'string'
        value = ls_entry-action ) TO lt_members.
      APPEND VALUE #( name = 'subject_type' kind = 'string'
        value = ls_entry-subject_type ) TO lt_members.
      APPEND VALUE #( name = 'subject_id' kind = 'string'
        value = ls_entry-subject_id ) TO lt_members.
      APPEND VALUE #( name = 'correlation_id' kind = 'string'
        value = ls_entry-correlation_id ) TO lt_members.
      APPEND VALUE #( name = 'occurred_at' kind = 'string'
        value = ls_entry-occurred_at ) TO lt_members.
      APPEND VALUE #( name = 'details' kind = 'string'
        value = ls_entry-details ) TO lt_members.
      IF lv_json <> '['.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize( lt_members ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
