CLASS zcl_hithub_tag_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_tag,
        object TYPE string,
        type   TYPE string,
        tag    TYPE string,
        tagger TYPE string,
        message TYPE string,
      END OF ty_tag.

    CLASS-METHODS encode
      IMPORTING
        is_tag TYPE ty_tag
      RETURNING
        VALUE(rv_payload) TYPE xstring
      RAISING
        cx_static_check.

    CLASS-METHODS decode
      IMPORTING
        iv_payload TYPE xstring
      RETURNING
        VALUE(rs_tag) TYPE ty_tag
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_tag_codec IMPLEMENTATION.

  METHOD encode.
    DATA lo_out TYPE REF TO cl_abap_conv_out_ce.
    DATA lv_text TYPE string.
    DATA lv_newline TYPE string.

    lv_newline = cl_abap_char_utilities=>newline.
    lv_text = |object { is_tag-object }| && lv_newline
      && |type { is_tag-type }| && lv_newline
      && |tag { is_tag-tag }| && lv_newline
      && |tagger { is_tag-tagger }| && lv_newline && lv_newline
      && is_tag-message.
    lo_out = cl_abap_conv_out_ce=>create( encoding = 'UTF-8' ).
    lo_out->write( data = lv_text ).
    rv_payload = lo_out->get_buffer( ).
  ENDMETHOD.

  METHOD decode.
    DATA lo_in TYPE REF TO cl_abap_conv_in_ce.
    DATA lv_text TYPE string.
    DATA lv_newline TYPE string.
    DATA lt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_line TYPE string.
    DATA lv_key TYPE string.
    DATA lv_value TYPE string.
    DATA lv_in_message TYPE abap_bool.

    CLEAR rs_tag.
    lv_newline = cl_abap_char_utilities=>newline.
    lo_in = cl_abap_conv_in_ce=>create( input = iv_payload encoding = 'UTF-8' ).
    lo_in->read( IMPORTING data = lv_text ).
    SPLIT lv_text AT lv_newline INTO TABLE lt_lines.
    LOOP AT lt_lines INTO lv_line.
      IF lv_in_message = abap_true.
        IF rs_tag-message IS INITIAL.
          rs_tag-message = lv_line.
        ELSE.
          rs_tag-message = rs_tag-message && lv_newline && lv_line.
        ENDIF.
        CONTINUE.
      ENDIF.
      IF lv_line IS INITIAL.
        lv_in_message = abap_true.
        CONTINUE.
      ENDIF.
      CLEAR: lv_key, lv_value.
      SPLIT lv_line AT space INTO lv_key lv_value.
      CASE lv_key.
        WHEN 'object'.
          rs_tag-object = lv_value.
        WHEN 'type'.
          rs_tag-type = lv_value.
        WHEN 'tag'.
          rs_tag-tag = lv_value.
        WHEN 'tagger'.
          rs_tag-tagger = lv_value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
