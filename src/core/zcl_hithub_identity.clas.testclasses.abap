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
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_identity=>is_valid(
        'Maintainer <maintainer@example.test> 0 +0000' ) ).
  ENDMETHOD.

  METHOD rejects_malformed_identity.
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_identity=>is_valid( 'maintainer@example.test' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_identity=>is_valid( 'Maintainer <maintainer@example.test>' ) ).
  ENDMETHOD.

ENDCLASS.
