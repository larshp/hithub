CLASS zcl_hithub_commit_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS one
      IMPORTING
        is_entry       TYPE zcl_hithub_commit_service=>ty_entry
      RETURNING
        VALUE(rv_body) TYPE xstring.

    CLASS-METHODS list
      IMPORTING
        it_entries     TYPE zcl_hithub_commit_service=>ty_entries
      RETURNING
        VALUE(rv_body) TYPE xstring.

  PRIVATE SECTION.
    CLASS-METHODS members
      IMPORTING
        is_entry          TYPE zcl_hithub_commit_service=>ty_entry
      RETURNING
        VALUE(rt_members) TYPE zcl_hithub_json=>ty_members.
    CLASS-METHODS serialize
      IMPORTING
        is_entry       TYPE zcl_hithub_commit_service=>ty_entry
      RETURNING
        VALUE(rv_json) TYPE string.

ENDCLASS.

CLASS zcl_hithub_commit_repr IMPLEMENTATION.

  METHOD members.
    APPEND VALUE #( name = 'oid' kind = 'string'
      value = is_entry-oid ) TO rt_members.
    APPEND VALUE #( name = 'algorithm' kind = 'string'
      value = is_entry-algorithm ) TO rt_members.
    APPEND VALUE #( name = 'tree' kind = 'string'
      value = is_entry-tree ) TO rt_members.
    APPEND VALUE #( name = 'author' kind = 'string'
      value = is_entry-author ) TO rt_members.
    APPEND VALUE #( name = 'committer' kind = 'string'
      value = is_entry-committer ) TO rt_members.
    APPEND VALUE #( name = 'message' kind = 'string'
      value = is_entry-message ) TO rt_members.
    IF is_entry-authored_at IS NOT INITIAL.
      APPEND VALUE #( name = 'authored_at' kind = 'string'
        value = is_entry-authored_at ) TO rt_members.
    ENDIF.
  ENDMETHOD.

  METHOD serialize.
    DATA lv_parent TYPE string.
    DATA lv_last TYPE i.

    rv_json = zcl_hithub_json=>serialize( members( is_entry ) ).
    lv_last = strlen( rv_json ) - 1.
    rv_json = rv_json(lv_last) && ',"parents":['.
    LOOP AT is_entry-parents INTO lv_parent.
      IF sy-tabix > 1.
        rv_json = rv_json && ','.
      ENDIF.
      rv_json = rv_json && '"' && lv_parent && '"'.
    ENDLOOP.
    rv_json = rv_json && ']}' .
  ENDMETHOD.

  METHOD one.
    rv_body = cl_abap_codepage=>convert_to( serialize( is_entry ) ).
  ENDMETHOD.

  METHOD list.
    DATA lv_json TYPE string.
    DATA ls_entry TYPE zcl_hithub_commit_service=>ty_entry.

    lv_json = '['.
    LOOP AT it_entries INTO ls_entry.
      IF sy-tabix > 1.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && serialize( ls_entry ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

ENDCLASS.
