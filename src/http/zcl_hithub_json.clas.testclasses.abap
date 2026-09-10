CLASS ltcl_hithub_json DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS parses_flat_json_object FOR TESTING RAISING cx_static_check.
    METHODS rejects_malformed_json FOR TESTING RAISING cx_static_check.
    METHODS serializes_and_escapes_values FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_hithub_json IMPLEMENTATION.

  METHOD parses_flat_json_object.
    DATA(ls_document) = zcl_hithub_json=>parse(
      iv_json = '{"name":"demo","count":2,"enabled":true,"empty":null}' ).
    DATA ls_member TYPE zcl_hithub_json=>ty_member.

    cl_abap_unit_assert=>assert_true( act = ls_document-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_document-members )
      exp = 4 ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'name'.
    cl_abap_unit_assert=>assert_equals( act = ls_member-kind exp = 'string' ).
    cl_abap_unit_assert=>assert_equals( act = ls_member-value exp = 'demo' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'count'.
    cl_abap_unit_assert=>assert_equals( act = ls_member-kind exp = 'number' ).
    cl_abap_unit_assert=>assert_equals( act = ls_member-value exp = '2' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'enabled'.
    cl_abap_unit_assert=>assert_equals( act = ls_member-kind exp = 'boolean' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'empty'.
    cl_abap_unit_assert=>assert_equals( act = ls_member-kind exp = 'null' ).
  ENDMETHOD.

  METHOD rejects_malformed_json.
    DATA(ls_document) = zcl_hithub_json=>parse(
      iv_json = '{"name":}' ).
    cl_abap_unit_assert=>assert_false( act = ls_document-valid ).

    ls_document = zcl_hithub_json=>parse(
      iv_json = '{"name":"unterminated}' ).
    cl_abap_unit_assert=>assert_false( act = ls_document-valid ).
  ENDMETHOD.

  METHOD serializes_and_escapes_values.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_newline TYPE string.

    lv_newline = cl_abap_char_utilities=>newline.
    ls_member-name = 'message'.
    ls_member-kind = 'string'.
    ls_member-value = 'quote " slash \' && lv_newline && 'next'.
    APPEND ls_member TO lt_members.
    CLEAR ls_member.
    ls_member-name = 'count'.
    ls_member-kind = 'number'.
    ls_member-value = '42'.
    APPEND ls_member TO lt_members.

    DATA(lv_json) = zcl_hithub_json=>serialize( lt_members ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_json CS '\"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_json CS '\\' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_json CS '\n' ) ).
    DATA(ls_document) = zcl_hithub_json=>parse( lv_json ).
    cl_abap_unit_assert=>assert_true( act = ls_document-valid ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'message'.
    cl_abap_unit_assert=>assert_equals(
      act = ls_member-value
      exp = 'quote " slash \' && lv_newline && 'next' ).
  ENDMETHOD.

ENDCLASS.
