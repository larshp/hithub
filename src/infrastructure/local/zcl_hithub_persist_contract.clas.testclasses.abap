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

    ASSERT ls_repository-id = 'repo-fixture-000000000000000000000000000000'.
    ASSERT ls_repository-name = 'fixture-repository'.
    ASSERT ls_repository-description = 'Deterministic HitHub persistence fixture'.
    ASSERT ls_repository-default_branch = 'refs/heads/main'.
    ASSERT ls_repository-version = 1.
    ASSERT ls_repository-deleted = abap_false.

    ls_commit-tree = '1111111111111111111111111111111111111111'.
    ls_commit-author =
      'Fixture Author <fixture@example.invalid> 1704067200 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = |Fixture commit| && cl_abap_char_utilities=>newline.
    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    ASSERT xstrlen( lv_payload ) = 195.
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_payload ).
    ASSERT lv_oid = '962dc6e57082fe02604d1a93d0dd2d833da2dcfc'.

    ls_reference-repository_id = ls_repository-id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_oid.
    ls_reference-symbolic_target = ''.
    ls_reference-version = 1.
    ASSERT ls_reference-repository_id = ls_repository-id.
    ASSERT ls_reference-name = 'refs/heads/main'.
    ASSERT ls_reference-algorithm = 'sha1'.
    ASSERT ls_reference-oid = lv_oid.
    ASSERT ls_reference-symbolic_target IS INITIAL.
    ASSERT ls_reference-version = 1.

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
    ASSERT ls_reference-oid = lv_oid.
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

    ASSERT ls_read-id = ls_repository-id.
    ASSERT ls_read-name = ls_repository-name.
    ASSERT ls_read-default_branch = ls_repository-default_branch.
    ASSERT ls_read-version = 1.

    ls_repository-description = 'Updated persistence contract'.
    DATA(lv_version) = lo_store->zif_hithub_metadata_store~update_repository(
      is_repository = ls_repository iv_expected_version = 1 ).
    ASSERT lv_version = 2.
    lv_version = lo_store->zif_hithub_metadata_store~update_repository(
      is_repository = ls_repository iv_expected_version = 1 ).
    ASSERT lv_version = 0.
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
    ASSERT lv_version = 1.

    ls_reference-oid = '2222222222222222222222222222222222222222'.
    lv_version = lo_store->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 1 ).
    ASSERT lv_version = 2.

    lv_version = lo_store->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 1 ).
    ASSERT lv_version = 0.
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
    ASSERT lv_created = abap_true.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_object-key ) = abap_true.
    ls_read = lo_store->zif_hithub_object_store~read( ls_object-key ).

    ASSERT ls_read-type = ls_object-type.
    ASSERT ls_read-size = ls_object-size.
    ASSERT ls_read-payload = ls_object-payload.
  ENDMETHOD.

ENDCLASS.
