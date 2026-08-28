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

    ASSERT ls_decoded-object = ls_tag-object.
    ASSERT ls_decoded-type = ls_tag-type.
    ASSERT ls_decoded-tag = ls_tag-tag.
    ASSERT ls_decoded-tagger = ls_tag-tagger.
    ASSERT ls_decoded-message = ls_tag-message.
  ENDMETHOD.

ENDCLASS.
