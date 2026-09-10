CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trip_commit FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD round_trip_commit.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_decoded TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA lv_payload TYPE xstring.
    DATA lv_parent TYPE string.

    ls_commit-tree = '1111111111111111111111111111111111111111'.
    lv_parent = '2222222222222222222222222222222222222222'.
    APPEND lv_parent TO ls_commit-parents.
    ls_commit-author = 'Fixture Author <fixture@example.invalid> 1704067200 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = |Subject line| && cl_abap_char_utilities=>newline
      && |Body line|.

    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    ls_decoded = zcl_hithub_commit_codec=>decode( lv_payload ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-tree
      exp = ls_commit-tree ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_decoded-parents )
      exp = 1 ).
    READ TABLE ls_decoded-parents INTO lv_parent INDEX 1.
    cl_abap_unit_assert=>assert_equals(
      act = lv_parent
      exp = '2222222222222222222222222222222222222222' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-author
      exp = ls_commit-author ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-committer
      exp = ls_commit-committer ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-message
      exp = ls_commit-message ).
  ENDMETHOD.

ENDCLASS.
