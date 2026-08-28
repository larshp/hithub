CLASS ltcl_identity DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS accepts_git_identity FOR TESTING RAISING cx_static_check.
    METHODS rejects_malformed_identity FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_identity IMPLEMENTATION.

  METHOD accepts_git_identity.
    ASSERT zcl_hithub_identity=>is_valid(
      'Maintainer <maintainer@example.test> 0 +0000' ) = abap_true.
  ENDMETHOD.

  METHOD rejects_malformed_identity.
    ASSERT zcl_hithub_identity=>is_valid( 'maintainer@example.test' ) =
      abap_false.
    ASSERT zcl_hithub_identity=>is_valid( 'Maintainer <maintainer@example.test>' ) =
      abap_false.
  ENDMETHOD.

ENDCLASS.
