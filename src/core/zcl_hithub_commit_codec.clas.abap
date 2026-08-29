CLASS zcl_hithub_commit_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      ty_parents TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      BEGIN OF ty_commit,
        tree      TYPE string,
        parents   TYPE ty_parents,
        author    TYPE string,
        committer TYPE string,
        message   TYPE string,
      END OF ty_commit.

    CLASS-METHODS encode
      IMPORTING
        is_commit         TYPE ty_commit
      RETURNING
        VALUE(rv_payload) TYPE xstring
      RAISING
        cx_static_check.

    CLASS-METHODS decode
      IMPORTING
        iv_payload       TYPE xstring
      RETURNING
        VALUE(rs_commit) TYPE ty_commit
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_commit_codec IMPLEMENTATION.

  METHOD encode.
    DATA lo_out TYPE REF TO cl_abap_conv_out_ce.
    DATA lv_text TYPE string.
    DATA lv_newline TYPE string.

    lv_newline = cl_abap_char_utilities=>newline.
    lv_text = |tree { is_commit-tree }| && lv_newline.
    LOOP AT is_commit-parents INTO DATA(lv_parent).
      lv_text = lv_text && |parent { lv_parent }| && lv_newline.
    ENDLOOP.
    lv_text = lv_text && |author { is_commit-author }| && lv_newline
      && |committer { is_commit-committer }| && lv_newline && lv_newline
      && is_commit-message.

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

    CLEAR rs_commit.
    lv_newline = cl_abap_char_utilities=>newline.
    lo_in = cl_abap_conv_in_ce=>create( input = iv_payload encoding = 'UTF-8' ).
    lo_in->read( IMPORTING data = lv_text ).
    SPLIT lv_text AT lv_newline INTO TABLE lt_lines.

    LOOP AT lt_lines INTO lv_line.
      IF lv_in_message = abap_true.
        IF rs_commit-message IS INITIAL.
          rs_commit-message = lv_line.
        ELSE.
          rs_commit-message = rs_commit-message && lv_newline && lv_line.
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
        WHEN 'tree'.
          rs_commit-tree = lv_value.
        WHEN 'parent'.
          APPEND lv_value TO rs_commit-parents.
        WHEN 'author'.
          rs_commit-author = lv_value.
        WHEN 'committer'.
          rs_commit-committer = lv_value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
