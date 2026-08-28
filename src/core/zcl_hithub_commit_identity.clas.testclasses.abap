CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_identity_and_offset FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_identity_and_offset.
    DATA(ls_identity) = zcl_hithub_commit_identity=>parse(
      'Fixture Author <fixture@example.invalid> 1704067200 +0000' ).

    ASSERT ls_identity-name = 'Fixture Author'.
    ASSERT ls_identity-email = 'fixture@example.invalid'.
    ASSERT ls_identity-unix_seconds = 1704067200.
    ASSERT ls_identity-timezone = '+0000'.
  ENDMETHOD.

ENDCLASS.
