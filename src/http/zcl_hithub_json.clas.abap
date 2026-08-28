CLASS zcl_hithub_json DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_member.
    TYPES   name TYPE string.
    TYPES   kind TYPE string.
    TYPES   value TYPE string.
    TYPES END OF ty_member.
    TYPES ty_members TYPE STANDARD TABLE OF ty_member WITH DEFAULT KEY.

    TYPES BEGIN OF ty_document.
    TYPES   valid TYPE abap_bool.
    TYPES   members TYPE ty_members.
    TYPES END OF ty_document.

    CLASS-METHODS parse
      IMPORTING
        iv_json TYPE string
      RETURNING
        VALUE(rs_document) TYPE ty_document.
    CLASS-METHODS parse_data
      IMPORTING
        iv_json TYPE xstring
      RETURNING
        VALUE(rs_document) TYPE ty_document.
    CLASS-METHODS serialize
      IMPORTING
        it_members TYPE ty_members
      RETURNING
        VALUE(rv_json) TYPE string.
    CLASS-METHODS serialize_data
      IMPORTING
        it_members TYPE ty_members
      RETURNING
        VALUE(rv_json) TYPE xstring.

  PRIVATE SECTION.
    CLASS-METHODS skip_whitespace
      IMPORTING
        iv_json TYPE string
      CHANGING
        cv_offset TYPE i.
    CLASS-METHODS read_string
      IMPORTING
        iv_json TYPE string
      CHANGING
        cv_offset TYPE i
        cv_valid TYPE abap_bool
        cv_value TYPE string.
    CLASS-METHODS escape
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
ENDCLASS.

CLASS zcl_hithub_json IMPLEMENTATION.

  METHOD parse.
    DATA lv_offset TYPE i.
    DATA lv_length TYPE i.
    DATA lv_value_start TYPE i.
    DATA lv_token_length TYPE i.
    DATA lv_token TYPE string.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_valid TYPE abap_bool.
    DATA lv_string TYPE string.
    DATA ls_member TYPE ty_member.

    CLEAR rs_document.
    lv_length = strlen( iv_json ).
    lv_offset = 0.
    skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
    IF lv_offset >= lv_length OR iv_json+lv_offset(1) <> '{'.
      RETURN.
    ENDIF.
    lv_offset = lv_offset + 1.
    skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
    IF lv_offset < lv_length AND iv_json+lv_offset(1) = '}'.
      lv_offset = lv_offset + 1.
      skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
      IF lv_offset >= lv_length.
        rs_document-valid = abap_true.
      ENDIF.
      RETURN.
    ENDIF.

    WHILE lv_offset < lv_length.
      CLEAR ls_member.
      lv_valid = abap_true.
      CLEAR lv_string.
      read_string(
        EXPORTING iv_json = iv_json
        CHANGING cv_offset = lv_offset cv_valid = lv_valid cv_value = lv_string ).
      IF lv_valid = abap_false.
        RETURN.
      ENDIF.
      ls_member-name = lv_string.
      skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
      IF lv_offset >= lv_length OR iv_json+lv_offset(1) <> ':'.
        RETURN.
      ENDIF.
      lv_offset = lv_offset + 1.
      skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
      IF lv_offset >= lv_length.
        RETURN.
      ENDIF.

      lv_char = iv_json+lv_offset(1).
      IF lv_char = '"'.
        ls_member-kind = 'string'.
        CLEAR lv_string.
        read_string(
          EXPORTING iv_json = iv_json
          CHANGING cv_offset = lv_offset cv_valid = lv_valid cv_value = lv_string ).
        IF lv_valid = abap_false.
          RETURN.
        ENDIF.
        ls_member-value = lv_string.
      ELSE.
        lv_value_start = lv_offset.
        WHILE lv_offset < lv_length.
          lv_char = iv_json+lv_offset(1).
          IF lv_char = ',' OR lv_char = '}' OR lv_char = ' '
              OR lv_char IS INITIAL
              OR lv_char = cl_abap_char_utilities=>newline.
            EXIT.
          ENDIF.
          lv_offset = lv_offset + 1.
        ENDWHILE.
        IF lv_offset = lv_value_start.
          RETURN.
        ENDIF.
        lv_token_length = lv_offset - lv_value_start.
        lv_token = iv_json+lv_value_start(lv_token_length).
        IF lv_token = 'true' OR lv_token = 'false'.
          ls_member-kind = 'boolean'.
          ls_member-value = lv_token.
        ELSEIF lv_token = 'null'.
          ls_member-kind = 'null'.
        ELSE.
          FIND REGEX '^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
            IN lv_token.
          IF sy-subrc <> 0.
            RETURN.
          ENDIF.
          ls_member-kind = 'number'.
          ls_member-value = lv_token.
        ENDIF.
      ENDIF.
      APPEND ls_member TO rs_document-members.
      skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
      IF lv_offset >= lv_length.
        RETURN.
      ELSEIF iv_json+lv_offset(1) = '}'.
        lv_offset = lv_offset + 1.
        skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
        IF lv_offset >= lv_length.
          rs_document-valid = abap_true.
        ENDIF.
        RETURN.
      ELSEIF iv_json+lv_offset(1) = ','.
        lv_offset = lv_offset + 1.
        skip_whitespace( EXPORTING iv_json = iv_json CHANGING cv_offset = lv_offset ).
      ELSE.
        RETURN.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD parse_data.
    rs_document = parse( cl_abap_codepage=>convert_from( source = iv_json ) ).
  ENDMETHOD.

  METHOD serialize.
    DATA ls_member TYPE ty_member.

    rv_json = '{'.
    LOOP AT it_members INTO ls_member.
      IF sy-tabix > 1.
        rv_json = rv_json && ','.
      ENDIF.
      rv_json = rv_json && '"' && escape( ls_member-name ) && '":'.
      CASE ls_member-kind.
        WHEN 'string'.
          rv_json = rv_json && '"' && escape( ls_member-value ) && '"'.
        WHEN 'number' OR 'boolean'.
          rv_json = rv_json && ls_member-value.
        WHEN 'null'.
          rv_json = rv_json && 'null'.
        WHEN OTHERS.
          CLEAR rv_json.
          RETURN.
      ENDCASE.
    ENDLOOP.
    rv_json = rv_json && '}'.
  ENDMETHOD.

  METHOD serialize_data.
    rv_json = cl_abap_codepage=>convert_to(
      source = serialize( it_members ) ).
  ENDMETHOD.

  METHOD skip_whitespace.
    WHILE cv_offset < strlen( iv_json ).
      DATA lv_char TYPE c LENGTH 1.
      lv_char = iv_json+cv_offset(1).
      IF lv_char = ' ' OR lv_char IS INITIAL
          OR lv_char = cl_abap_char_utilities=>newline
          OR lv_char = cl_abap_char_utilities=>horizontal_tab
          OR lv_char = cl_abap_char_utilities=>cr_lf(1).
        cv_offset = cv_offset + 1.
      ELSE.
        RETURN.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD read_string.
    DATA lv_length TYPE i.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_escape TYPE c LENGTH 1.

    CLEAR cv_value.
    cv_valid = abap_false.
    lv_length = strlen( iv_json ).
    IF cv_offset >= lv_length OR iv_json+cv_offset(1) <> '"'.
      RETURN.
    ENDIF.
    cv_offset = cv_offset + 1.
    WHILE cv_offset < lv_length.
      lv_char = iv_json+cv_offset(1).
      cv_offset = cv_offset + 1.
      IF lv_char = '"'.
        cv_valid = abap_true.
        RETURN.
      ELSEIF lv_char <> '\'.
        IF lv_char IS INITIAL.
          cv_value = cv_value && | |.
        ELSE.
          cv_value = cv_value && lv_char.
        ENDIF.
        CONTINUE.
      ENDIF.

      IF cv_offset >= lv_length.
        RETURN.
      ENDIF.
      lv_escape = iv_json+cv_offset(1).
      cv_offset = cv_offset + 1.
      CASE lv_escape.
        WHEN '"'.
          cv_value = cv_value && '"'.
        WHEN '\'.
          cv_value = cv_value && '\'.
        WHEN '/'.
          cv_value = cv_value && '/'.
        WHEN 'b'.
          cv_value = cv_value && cl_abap_char_utilities=>backspace.
        WHEN 'f'.
          cv_value = cv_value && cl_abap_char_utilities=>form_feed.
        WHEN 'n'.
          cv_value = cv_value && cl_abap_char_utilities=>newline.
        WHEN 'r'.
          cv_value = cv_value && cl_abap_char_utilities=>cr_lf(1).
        WHEN 't'.
          cv_value = cv_value && cl_abap_char_utilities=>horizontal_tab.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDWHILE.
  ENDMETHOD.

  METHOD escape.
    DATA lv_offset TYPE i.
    DATA lv_char TYPE c LENGTH 1.

    CLEAR rv_value.
    WHILE lv_offset < strlen( iv_value ).
      lv_char = iv_value+lv_offset(1).
      CASE lv_char.
        WHEN '"'.
          rv_value = rv_value && '\"'.
        WHEN '\'.
          rv_value = rv_value && '\\'.
        WHEN cl_abap_char_utilities=>backspace.
          rv_value = rv_value && '\b'.
        WHEN cl_abap_char_utilities=>form_feed.
          rv_value = rv_value && '\f'.
        WHEN cl_abap_char_utilities=>newline.
          rv_value = rv_value && '\n'.
        WHEN cl_abap_char_utilities=>cr_lf(1).
          rv_value = rv_value && '\r'.
        WHEN cl_abap_char_utilities=>horizontal_tab.
          rv_value = rv_value && '\t'.
        WHEN OTHERS.
          IF lv_char IS INITIAL.
            rv_value = rv_value && | |.
          ELSE.
            rv_value = rv_value && lv_char.
          ENDIF.
      ENDCASE.
      lv_offset = lv_offset + 1.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
