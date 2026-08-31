CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS accepts_normal_refs FOR TESTING RAISING cx_static_check.
    METHODS rejects_forbidden_refs FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD accepts_normal_refs.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/main' ) = abap_true.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/tags/v1.2.3' ) = abap_true.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'topic/feature_x' ) = abap_true.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'a@b' ) = abap_true.
  ENDMETHOD.

  METHOD rejects_forbidden_refs.
    ASSERT zcl_hithub_ref_validator=>is_valid( '' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( '@' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( '/main' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'main/' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'feature//x' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'feature..x' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'feature@{x' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/.hidden' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/main.' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/main x' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/main~x' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/main[x' ) = abap_false.
    ASSERT zcl_hithub_ref_validator=>is_valid( 'refs/heads/main\\x' ) = abap_false.
  ENDMETHOD.

ENDCLASS.
