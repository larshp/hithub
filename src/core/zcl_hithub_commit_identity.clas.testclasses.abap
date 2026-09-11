CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_identity_and_offset FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_identity_and_offset.
    DATA(ls_identity) = zcl_hithub_commit_identity=>parse(
      'Fixture Author <fixture@example.invalid> 1704067200 +0000' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_identity-name
      exp = 'Fixture Author' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_identity-email
      exp = 'fixture@example.invalid' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_identity-unix_seconds
      exp = 1704067200 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_identity-timezone
      exp = '+0000' ).
  ENDMETHOD.

ENDCLASS.
