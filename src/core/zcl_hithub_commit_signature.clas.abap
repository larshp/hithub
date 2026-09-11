CLASS zcl_hithub_commit_signature DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_fallback_name TYPE string VALUE 'HitHub'.
    CONSTANTS c_domain TYPE string VALUE 'hithub.invalid'.

    "! Builds the counterpart of what zcl_hithub_commit_identity parses, so a
    "! generated signature always satisfies zcl_hithub_identity=>is_valid.
    CLASS-METHODS build
      IMPORTING
        iv_name            TYPE string
        iv_email           TYPE string OPTIONAL
        iv_unix_seconds    TYPE int8 OPTIONAL
      RETURNING
        VALUE(rv_identity) TYPE string
      RAISING
        cx_static_check.

    CLASS-METHODS now_seconds
      RETURNING
        VALUE(rv_seconds) TYPE int8
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    CLASS-METHODS clean
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
ENDCLASS.

CLASS zcl_hithub_commit_signature IMPLEMENTATION.

  METHOD clean.
    rv_value = iv_value.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN rv_value
      WITH ` `.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf(1) IN rv_value
      WITH ` `.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab
      IN rv_value WITH ` `.
    REPLACE ALL OCCURRENCES OF '<' IN rv_value WITH ''.
    REPLACE ALL OCCURRENCES OF '>' IN rv_value WITH ''.
    CONDENSE rv_value.
  ENDMETHOD.

  METHOD now_seconds.
    CONSTANTS lc_epoch TYPE timestamp VALUE '19700101000000'.
    DATA lv_now TYPE timestamp.

    GET TIME STAMP FIELD lv_now.
    rv_seconds = CONV int8( cl_abap_tstmp=>subtract(
      tstmp1 = lv_now tstmp2 = lc_epoch ) ).
    IF rv_seconds < 0.
      rv_seconds = 0.
    ENDIF.
  ENDMETHOD.

  METHOD build.
    DATA lv_name TYPE string.
    DATA lv_email TYPE string.
    DATA lv_seconds TYPE int8.

    lv_name = clean( iv_name ).
    IF lv_name IS INITIAL.
      lv_name = c_fallback_name.
    ENDIF.
    lv_email = clean( iv_email ).
    IF lv_email IS INITIAL.
      lv_email = lv_name.
    ENDIF.
    REPLACE ALL OCCURRENCES OF ` ` IN lv_email WITH '-'.
    TRANSLATE lv_email TO LOWER CASE.
    IF lv_email NS '@'.
      lv_email = |{ lv_email }@{ c_domain }|.
    ENDIF.
    lv_seconds = iv_unix_seconds.
    IF lv_seconds <= 0.
      lv_seconds = now_seconds( ).
    ENDIF.
    rv_identity = |{ lv_name } <{ lv_email }> { lv_seconds } +0000|.
  ENDMETHOD.

ENDCLASS.
