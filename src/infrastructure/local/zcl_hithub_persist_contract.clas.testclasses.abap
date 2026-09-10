CLASS ltcl_persist_contract DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS preserves_fixture_contract FOR TESTING RAISING cx_static_check.
    METHODS repository_roundtrip FOR TESTING RAISING cx_static_check.
    METHODS reference_compare_and_swap FOR TESTING RAISING cx_static_check.
    METHODS object_roundtrip FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_persist_contract IMPLEMENTATION.

  METHOD preserves_fixture_contract.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.

    ls_repository-id = 'repo-fixture-000000000000000000000000000000'.
    ls_repository-name = 'fixture-repository'.
    ls_repository-description = 'Deterministic HitHub persistence fixture'.
    ls_repository-default_branch = 'refs/heads/main'.
    ls_repository-version = 1.
    ls_repository-deleted = abap_false.

    cl_abap_unit_assert=>assert_equals(
      act = ls_repository-id
      exp = 'repo-fixture-000000000000000000000000000000' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_repository-name
      exp = 'fixture-repository' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_repository-description
      exp = 'Deterministic HitHub persistence fixture' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_repository-default_branch
      exp = 'refs/heads/main' ).
    cl_abap_unit_assert=>assert_equals( act = ls_repository-version exp = 1 ).
    cl_abap_unit_assert=>assert_false( act = ls_repository-deleted ).

    ls_commit-tree = '1111111111111111111111111111111111111111'.
    ls_commit-author =
      'Fixture Author <fixture@example.invalid> 1704067200 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = |Fixture commit| && cl_abap_char_utilities=>newline.
    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    cl_abap_unit_assert=>assert_equals( act = xstrlen( lv_payload ) exp = 195 ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = '962dc6e57082fe02604d1a93d0dd2d833da2dcfc' ).

    ls_reference-repository_id = ls_repository-id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_oid.
    ls_reference-symbolic_target = ''.
    ls_reference-version = 1.
    cl_abap_unit_assert=>assert_equals(
      act = ls_reference-repository_id
      exp = ls_repository-id ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_reference-name
      exp = 'refs/heads/main' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_reference-algorithm
      exp = 'sha1' ).
    cl_abap_unit_assert=>assert_equals( act = ls_reference-oid exp = lv_oid ).
    cl_abap_unit_assert=>assert_initial( act = ls_reference-symbolic_target ).
    cl_abap_unit_assert=>assert_equals( act = ls_reference-version exp = 1 ).

    CLEAR ls_commit.
    ls_commit-tree = '1111111111111111111111111111111111111111'.
    ls_commit-author =
      'Fixture Author <fixture@example.invalid> 1704067200 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = |Ref target| && cl_abap_char_utilities=>newline.
    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_payload ).
    ls_reference-oid = lv_oid.
    cl_abap_unit_assert=>assert_equals( act = ls_reference-oid exp = lv_oid ).
  ENDMETHOD.

  METHOD repository_roundtrip.
    DATA(lo_store) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_read TYPE zif_hithub_metadata_store=>ty_repository.

    ls_repository-id = 'contract-repository-000000000000000'.
    ls_repository-name = 'contract-repository'.
    ls_repository-description = 'Persistence contract'.
    ls_repository-default_branch = 'refs/heads/main'.
    ls_repository-version = 1.
    lo_store->zif_hithub_metadata_store~save_repository( ls_repository ).
    ls_read = lo_store->zif_hithub_metadata_store~read_repository( ls_repository-id ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_read-id
      exp = ls_repository-id ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-name
      exp = ls_repository-name ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-default_branch
      exp = ls_repository-default_branch ).
    cl_abap_unit_assert=>assert_equals( act = ls_read-version exp = 1 ).

    ls_repository-description = 'Updated persistence contract'.
    DATA(lv_version) = lo_store->zif_hithub_metadata_store~update_repository(
      is_repository = ls_repository iv_expected_version = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lv_version exp = 2 ).
    lv_version = lo_store->zif_hithub_metadata_store~update_repository(
      is_repository = ls_repository iv_expected_version = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lv_version exp = 0 ).
  ENDMETHOD.

  METHOD reference_compare_and_swap.
    DATA(lo_store) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_version TYPE int8.

    ls_reference-repository_id = 'contract-repository-000000000000000'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    lv_version = lo_store->zif_hithub_metadata_store~save_reference( ls_reference ).
    cl_abap_unit_assert=>assert_equals( act = lv_version exp = 1 ).

    ls_reference-oid = '2222222222222222222222222222222222222222'.
    lv_version = lo_store->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lv_version exp = 2 ).

    lv_version = lo_store->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lv_version exp = 0 ).
  ENDMETHOD.

  METHOD object_roundtrip.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_read TYPE zif_hithub_object_store=>ty_object.
    DATA lv_created TYPE abap_bool.

    ls_object-key-repository_id = 'contract-repository-000000000000000'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = '3333333333333333333333333333333333333333'.
    ls_object-type = 'blob'.
    ls_object-size = 2.
    ls_object-payload = CONV xstring( 'CAFE' ).
    lv_created = lo_store->zif_hithub_object_store~write( ls_object ).
    cl_abap_unit_assert=>assert_true( act = lv_created ).
    cl_abap_unit_assert=>assert_true(
      act = lo_store->zif_hithub_object_store~contains( ls_object-key ) ).
    ls_read = lo_store->zif_hithub_object_store~read( ls_object-key ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_read-type
      exp = ls_object-type ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-size
      exp = ls_object-size ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-payload
      exp = ls_object-payload ).
  ENDMETHOD.

ENDCLASS.
