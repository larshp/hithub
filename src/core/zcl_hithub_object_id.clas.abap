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

    "! Packs an object id into the raw bytes a tree entry or a pack entry
    "! carries. Character to byte conversion reads upper case hex digits
    "! and stops at the first other character, so the lower case id has to
    "! be folded up first.
    CLASS-METHODS to_bytes
      IMPORTING
        iv_oid          TYPE string
      RETURNING
        VALUE(rv_bytes) TYPE xstring.

    "! Unpacks the raw bytes of a tree entry or a pack entry back into an
    "! object id. Byte to character conversion renders upper case hex,
    "! while ids are stored and compared in lower case.
    CLASS-METHODS from_bytes
      IMPORTING
        iv_bytes      TYPE xstring
      RETURNING
        VALUE(rv_oid) TYPE string.

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

  METHOD to_bytes.
    DATA lv_hex TYPE string.

    lv_hex = iv_oid.
    TRANSLATE lv_hex TO UPPER CASE.
    rv_bytes = lv_hex.
  ENDMETHOD.

  METHOD from_bytes.
    rv_oid = iv_bytes.
    TRANSLATE rv_oid TO LOWER CASE.
  ENDMETHOD.

ENDCLASS.
