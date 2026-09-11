CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS accepts_normal_refs FOR TESTING RAISING cx_static_check.
    METHODS rejects_forbidden_refs FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD accepts_normal_refs.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/main' ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/tags/v1.2.3' ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_ref_validator=>is_valid( 'topic/feature_x' ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_ref_validator=>is_valid( 'a@b' ) ).
  ENDMETHOD.

  METHOD rejects_forbidden_refs.
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( '' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( '@' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( '/main' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'main/' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'feature//x' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'feature..x' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'feature@{x' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/.hidden' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/main.' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/main x' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/main~x' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/main[x' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_ref_validator=>is_valid( 'refs/heads/main\\x' ) ).
  ENDMETHOD.

ENDCLASS.
