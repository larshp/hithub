CLASS zcl_hithub_object_header DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS generate
      IMPORTING
        iv_type          TYPE string
        iv_size          TYPE int8
      RETURNING
        VALUE(rv_header) TYPE xstring
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_object_header IMPLEMENTATION.

  METHOD generate.
    DATA lo_out TYPE REF TO cl_abap_conv_out_ce.
    DATA lv_zero TYPE x LENGTH 1.
    DATA lv_text TYPE string.
    DATA lv_size TYPE string.
    DATA lv_prefix TYPE xstring.

    lv_size = |{ iv_size }|.
    lv_text = |{ iv_type } { lv_size }|.
    lo_out = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
    lo_out->write( data = lv_text ).
    lv_prefix = lo_out->get_buffer( ).
    CONCATENATE lv_prefix lv_zero INTO rv_header IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
