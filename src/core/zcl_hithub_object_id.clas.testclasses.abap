CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS calculates_git_sha1 FOR TESTING RAISING cx_static_check.
    METHODS calculates_golden_ids FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD calculates_git_sha1.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.

    lv_payload = cl_abap_codepage=>convert_to( 'hello' ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).

    ASSERT lv_oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'.
  ENDMETHOD.

  METHOD calculates_golden_ids.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.
    DATA lv_byte TYPE xstring.

    CLEAR lv_payload.
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ASSERT lv_oid = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'.

    lv_payload = cl_abap_codepage=>convert_to( source = |hello{ cl_abap_char_utilities=>newline }| ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ASSERT lv_oid = 'ce013625030ba8dba906f756967f9e9ca394464a'.

    lv_payload = CONV xstring( '0001027F80FF' ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ASSERT lv_oid = 'ac0deae0c6de979e3136dcc6bdb1d07c58d37107'.

    lv_payload = cl_abap_codepage=>convert_to(
      source = |Hällo 🌍{ cl_abap_char_utilities=>newline }| ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ASSERT lv_oid = '83d5089f5ae0d203e46984bbddffe11606382cf0'.

    CLEAR lv_payload.
    lv_byte = CONV xstring( '61' ).
    DO 4096 TIMES.
      CONCATENATE lv_payload lv_byte INTO lv_payload IN BYTE MODE.
    ENDDO.
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ASSERT lv_oid = '9d235ed07cd19811a6ceb342de82f190e49c9f68'.
  ENDMETHOD.

ENDCLASS.
