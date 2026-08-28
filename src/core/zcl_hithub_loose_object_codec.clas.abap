CLASS zcl_hithub_loose_object_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_object,
        type    TYPE string,
        size    TYPE int8,
        payload TYPE xstring,
      END OF ty_object.

    METHODS constructor
      IMPORTING
        io_compression TYPE REF TO zif_hithub_compression.

    METHODS compress
      IMPORTING
        iv_type    TYPE string
        iv_payload TYPE xstring
      RETURNING
        VALUE(rv_data) TYPE xstring
      RAISING
        cx_static_check.

    METHODS decompress
      IMPORTING
        iv_data     TYPE xstring
        iv_max_size TYPE int8 DEFAULT 524288000
      RETURNING
        VALUE(rs_object) TYPE ty_object
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_compression TYPE REF TO zif_hithub_compression.

ENDCLASS.

CLASS zcl_hithub_loose_object_codec IMPLEMENTATION.

  METHOD constructor.
    mo_compression = io_compression.
  ENDMETHOD.

  METHOD compress.
    DATA lv_header TYPE xstring.
    DATA lv_raw TYPE xstring.

    CLEAR rv_data.
    IF mo_compression IS INITIAL.
      RETURN.
    ENDIF.
    lv_header = zcl_hithub_object_header=>generate(
      iv_type = iv_type iv_size = xstrlen( iv_payload ) ).
    CONCATENATE lv_header iv_payload INTO lv_raw IN BYTE MODE.
    rv_data = mo_compression->compress( lv_raw ).
  ENDMETHOD.

  METHOD decompress.
    DATA lv_raw TYPE xstring.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_header_length TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_zero TYPE x LENGTH 1.
    DATA lv_header TYPE xstring.
    DATA lo_in TYPE REF TO cl_abap_conv_in_ce.
    DATA lv_text TYPE string.
    DATA lv_size_text TYPE string.
    DATA lv_payload_offset TYPE i.

    CLEAR rs_object.
    IF mo_compression IS INITIAL.
      RETURN.
    ENDIF.
    lv_raw = mo_compression->decompress( iv_data ).
    IF iv_max_size < 0 OR xstrlen( lv_raw ) > iv_max_size.
      RETURN.
    ENDIF.
    lv_length = xstrlen( lv_raw ).
    lv_offset = 0.
    WHILE lv_offset < lv_length.
      lv_byte = lv_raw+lv_offset(1).
      IF lv_byte = lv_zero.
        EXIT.
      ENDIF.
      lv_offset = lv_offset + 1.
    ENDWHILE.
    IF lv_offset >= lv_length.
      RETURN.
    ENDIF.

    lv_header_length = lv_offset.
    lv_header = lv_raw+0(lv_header_length).
    lo_in = cl_abap_conv_in_ce=>create( input = lv_header encoding = 'UTF-8' ).
    lo_in->read( IMPORTING data = lv_text ).
    SPLIT lv_text AT space INTO rs_object-type lv_size_text.
    IF rs_object-type IS INITIAL OR lv_size_text IS INITIAL.
      CLEAR rs_object.
      RETURN.
    ENDIF.
    FIND REGEX '^[0-9]+$' IN lv_size_text.
    IF sy-subrc <> 0.
      CLEAR rs_object.
      RETURN.
    ENDIF.
    rs_object-size = CONV int8( lv_size_text ).
    lv_payload_offset = lv_offset + 1.
    IF lv_payload_offset > lv_length
        OR xstrlen( lv_raw+lv_payload_offset ) <> rs_object-size.
      CLEAR rs_object.
      RETURN.
    ENDIF.
    rs_object-payload = lv_raw+lv_payload_offset.
  ENDMETHOD.

ENDCLASS.
