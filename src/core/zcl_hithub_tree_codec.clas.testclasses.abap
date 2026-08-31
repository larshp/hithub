CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trip_entry FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD round_trip_entry.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_decoded TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA lv_oid TYPE xstring.
    DATA lv_oid_two TYPE xstring.
    DATA lv_oid_three TYPE xstring.
    DATA lv_payload TYPE xstring.

    lv_oid = CONV xstring( '1234567890123456789012345678901234567890' ).
    ls_entry-mode = '100644'.
    ls_entry-name = 'z.txt'.
    ls_entry-oid = lv_oid.
    APPEND ls_entry TO lt_entries.
    lv_oid_two = CONV xstring( '2234567890123456789012345678901234567890' ).
    ls_entry-mode = '040000'.
    ls_entry-name = 'a'.
    ls_entry-oid = lv_oid_two.
    APPEND ls_entry TO lt_entries.
    lv_oid_three = CONV xstring( '3234567890123456789012345678901234567890' ).
    ls_entry-mode = '100644'.
    ls_entry-name = 'a.txt'.
    ls_entry-oid = lv_oid_three.
    APPEND ls_entry TO lt_entries.

    lv_payload = zcl_hithub_tree_codec=>encode( lt_entries ).
    lt_decoded = zcl_hithub_tree_codec=>decode( lv_payload ).
    READ TABLE lt_decoded INTO ls_entry INDEX 1.

    ASSERT sy-subrc = 0.
    ASSERT lines( lt_decoded ) = 3.
    ASSERT ls_entry-mode = '100644'.
    ASSERT ls_entry-name = 'a.txt'.
    ASSERT ls_entry-oid = lv_oid_three.
    READ TABLE lt_decoded INTO ls_entry INDEX 2.
    ASSERT ls_entry-mode = '040000'.
    ASSERT ls_entry-name = 'a'.
    READ TABLE lt_decoded INTO ls_entry INDEX 3.
    ASSERT ls_entry-mode = '100644'.
    ASSERT ls_entry-name = 'z.txt'.
  ENDMETHOD.

ENDCLASS.
