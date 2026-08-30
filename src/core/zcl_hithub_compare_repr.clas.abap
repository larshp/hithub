CLASS zcl_hithub_compare_repr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS one
      IMPORTING
        is_comparison  TYPE zcl_hithub_compare_service=>ty_comparison
      RETURNING
        VALUE(rv_body) TYPE xstring.

  PRIVATE SECTION.
    CLASS-METHODS object
      IMPORTING
        it_members     TYPE zcl_hithub_json=>ty_members
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS open_object
      IMPORTING
        it_members     TYPE zcl_hithub_json=>ty_members
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS file
      IMPORTING
        is_file        TYPE zcl_hithub_compare_service=>ty_file
      RETURNING
        VALUE(rv_json) TYPE string.
ENDCLASS.

CLASS zcl_hithub_compare_repr IMPLEMENTATION.

  METHOD one.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lt_summary TYPE zcl_hithub_json=>ty_members.
    DATA ls_file TYPE zcl_hithub_compare_service=>ty_file.
    DATA lv_json TYPE string.
    DATA lv_files TYPE string.

    APPEND VALUE #( name = 'base_ref' kind = 'string'
      value = is_comparison-base_ref ) TO lt_members.
    APPEND VALUE #( name = 'head_ref' kind = 'string'
      value = is_comparison-head_ref ) TO lt_members.
    APPEND VALUE #( name = 'base_oid' kind = 'string'
      value = is_comparison-base_oid ) TO lt_members.
    APPEND VALUE #( name = 'head_oid' kind = 'string'
      value = is_comparison-head_oid ) TO lt_members.
    APPEND VALUE #( name = 'merge_base_oid' kind = 'string'
      value = is_comparison-merge_base_oid ) TO lt_members.
    APPEND VALUE #( name = 'additions' kind = 'number'
      value = |{ is_comparison-additions }| ) TO lt_members.
    APPEND VALUE #( name = 'deletions' kind = 'number'
      value = |{ is_comparison-deletions }| ) TO lt_members.

    APPEND VALUE #( name = 'added' kind = 'number'
      value = |{ is_comparison-summary-added }| ) TO lt_summary.
    APPEND VALUE #( name = 'modified' kind = 'number'
      value = |{ is_comparison-summary-modified }| ) TO lt_summary.
    APPEND VALUE #( name = 'deleted' kind = 'number'
      value = |{ is_comparison-summary-deleted }| ) TO lt_summary.
    APPEND VALUE #( name = 'total' kind = 'number'
      value = |{ is_comparison-summary-total }| ) TO lt_summary.

    LOOP AT is_comparison-files INTO ls_file.
      IF lv_files IS NOT INITIAL.
        lv_files = lv_files && ','.
      ENDIF.
      lv_files = lv_files && file( ls_file ).
    ENDLOOP.

    lv_json = open_object( lt_members )
      && ',"summary":' && object( lt_summary )
      && ',"files":[' && lv_files && ']}'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

  METHOD file.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.

    APPEND VALUE #( name = 'path' kind = 'string'
      value = is_file-path ) TO lt_members.
    APPEND VALUE #( name = 'status' kind = 'string'
      value = is_file-status ) TO lt_members.
    APPEND VALUE #( name = 'old_oid' kind = 'string'
      value = is_file-old_oid ) TO lt_members.
    APPEND VALUE #( name = 'new_oid' kind = 'string'
      value = is_file-new_oid ) TO lt_members.
    APPEND VALUE #( name = 'additions' kind = 'number'
      value = |{ is_file-additions }| ) TO lt_members.
    APPEND VALUE #( name = 'deletions' kind = 'number'
      value = |{ is_file-deletions }| ) TO lt_members.
    APPEND VALUE #( name = 'binary' kind = 'boolean'
      value = COND string( WHEN is_file-binary = abap_true
        THEN 'true' ELSE 'false' ) ) TO lt_members.
    APPEND VALUE #( name = 'truncated' kind = 'boolean'
      value = COND string( WHEN is_file-truncated = abap_true
        THEN 'true' ELSE 'false' ) ) TO lt_members.
    APPEND VALUE #( name = 'patch' kind = 'string'
      value = is_file-patch ) TO lt_members.
    rv_json = object( lt_members ).
  ENDMETHOD.

  METHOD object.
    rv_json = zcl_hithub_json=>serialize( it_members ).
  ENDMETHOD.

  METHOD open_object.
    DATA lv_json TYPE string.
    DATA lv_length TYPE i.

    lv_json = zcl_hithub_json=>serialize( it_members ).
    lv_length = strlen( lv_json ) - 1.
    rv_json = lv_json+0(lv_length).
  ENDMETHOD.

ENDCLASS.
