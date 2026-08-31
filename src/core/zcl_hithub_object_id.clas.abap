CLASS zcl_hithub_object_id DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS calculate
      IMPORTING
        iv_algorithm  TYPE string DEFAULT 'sha1'
        iv_type       TYPE string
        iv_payload    TYPE xstring
      RETURNING
        VALUE(rv_oid) TYPE string
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_object_id IMPLEMENTATION.

  METHOD calculate.
    DATA lv_header TYPE xstring.
    DATA lv_input TYPE xstring.
    DATA lv_hash TYPE xstring.

    lv_header = zcl_hithub_object_header=>generate(
      iv_type = iv_type iv_size = xstrlen( iv_payload ) ).
    CONCATENATE lv_header iv_payload INTO lv_input IN BYTE MODE.
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING
        if_algorithm   = iv_algorithm
        if_data        = lv_input
      IMPORTING
        ef_hashxstring = lv_hash ).
    rv_oid = lv_hash.
    TRANSLATE rv_oid TO LOWER CASE.
  ENDMETHOD.

ENDCLASS.
