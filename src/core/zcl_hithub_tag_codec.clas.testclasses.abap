CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trip_tag FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD round_trip_tag.
    DATA ls_tag TYPE zcl_hithub_tag_codec=>ty_tag.
    DATA ls_decoded TYPE zcl_hithub_tag_codec=>ty_tag.
    DATA lv_payload TYPE xstring.

    ls_tag-object = '1111111111111111111111111111111111111111'.
    ls_tag-type = 'commit'.
    ls_tag-tag = 'v1.0.0'.
    ls_tag-tagger = 'Fixture Tagger <fixture@example.invalid> 1704067200 +0000'.
    ls_tag-message = |Release tag| && cl_abap_char_utilities=>newline && |Notes|.

    lv_payload = zcl_hithub_tag_codec=>encode( ls_tag ).
    ls_decoded = zcl_hithub_tag_codec=>decode( lv_payload ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-object
      exp = ls_tag-object ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-type
      exp = ls_tag-type ).
    cl_abap_unit_assert=>assert_equals( act = ls_decoded-tag exp = ls_tag-tag ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-tagger
      exp = ls_tag-tagger ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-message
      exp = ls_tag-message ).
  ENDMETHOD.

ENDCLASS.
