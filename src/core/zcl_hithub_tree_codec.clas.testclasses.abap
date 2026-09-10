CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trip_entry FOR TESTING RAISING cx_static_check.
    METHODS keeps_oid_case_round_trip FOR TESTING RAISING cx_static_check.
    METHODS separates_trees_by_entry_oid FOR TESTING RAISING cx_static_check.

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

    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_decoded ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-mode exp = '100644' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-name exp = 'a.txt' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-oid exp = lv_oid_three ).
    READ TABLE lt_decoded INTO ls_entry INDEX 2.
    cl_abap_unit_assert=>assert_equals( act = ls_entry-mode exp = '040000' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-name exp = 'a' ).
    READ TABLE lt_decoded INTO ls_entry INDEX 3.
    cl_abap_unit_assert=>assert_equals( act = ls_entry-mode exp = '100644' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-name exp = 'z.txt' ).
  ENDMETHOD.

  METHOD keeps_oid_case_round_trip.
    " Every fixture above uses digits only, but real object ids are lower
    " case sha1 hex. Callers hand the raw bytes to the codec and turn the
    " decoded bytes back into a string to look the object up again, so
    " that loop has to be lossless.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_decoded TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA lv_oid TYPE string.

    lv_oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'.
    ls_entry-mode = '100644'.
    ls_entry-name = 'file.txt'.
    ls_entry-oid = zcl_hithub_object_id=>to_bytes( lv_oid ).
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( ls_entry-oid )
      exp = 20
      msg = 'the entry oid is not 20 bytes before encoding' ).
    APPEND ls_entry TO lt_entries.

    lt_decoded = zcl_hithub_tree_codec=>decode(
      zcl_hithub_tree_codec=>encode( lt_entries ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_decoded ) exp = 1 ).
    READ TABLE lt_decoded INTO ls_entry INDEX 1.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( ls_entry-oid )
      exp = 20
      msg = 'the decoded entry oid is not 20 bytes' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_object_id=>from_bytes( ls_entry-oid )
      exp = lv_oid
      msg = 'the oid does not survive encode and decode' ).
  ENDMETHOD.

  METHOD separates_trees_by_entry_oid.
    " Compare, the file editor and the pack codec all build trees that
    " differ only in the entry oid, so those must not encode identically.
    DATA lt_first TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA lt_second TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.

    ls_entry-mode = '100644'.
    ls_entry-name = 'file.txt'.
    ls_entry-oid = zcl_hithub_object_id=>to_bytes(
      'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' ).
    APPEND ls_entry TO lt_first.
    ls_entry-oid = zcl_hithub_object_id=>to_bytes(
      'ce013625030ba8dba906f756967f9e9ca394464a' ).
    APPEND ls_entry TO lt_second.

    cl_abap_unit_assert=>assert_differs(
      act = zcl_hithub_tree_codec=>encode( lt_first )
      exp = zcl_hithub_tree_codec=>encode( lt_second )
      msg = 'trees differing only in the entry oid encode identically' ).
  ENDMETHOD.

ENDCLASS.
