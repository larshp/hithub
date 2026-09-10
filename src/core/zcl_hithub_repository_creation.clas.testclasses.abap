CLASS lcl_repository_identity DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_identity.

ENDCLASS.

CLASS lcl_repository_identity IMPLEMENTATION.

  METHOD zif_hithub_identity~uuid.
    rv_uuid = '00000000-0000-4000-8000-000000000001'.
  ENDMETHOD.

  METHOD zif_hithub_identity~random_bytes.
    rv_bytes = CONV xstring( 'CAFE' ).
  ENDMETHOD.

ENDCLASS.

CLASS lcl_second_repository_identity DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_identity.

ENDCLASS.

CLASS lcl_second_repository_identity IMPLEMENTATION.

  METHOD zif_hithub_identity~uuid.
    rv_uuid = '00000000-0000-4000-8000-000000000002'.
  ENDMETHOD.

  METHOD zif_hithub_identity~random_bytes.
    rv_bytes = CONV xstring( 'BEEF' ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_repository_creation DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS creates_normalized_repository FOR TESTING RAISING cx_static_check.
    METHODS rejects_duplicate_name FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_name FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_repository_creation IMPLEMENTATION.

  METHOD creates_normalized_repository.
    DATA lv_readme TYPE string.
    DATA lo_readme TYPE REF TO cl_abap_conv_in_ce.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_objects) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_identity) = NEW lcl_repository_identity( ).
    DATA(lo_service) = NEW zcl_hithub_repository_creation(
      io_metadata = lo_metadata io_transaction = lo_transaction
      io_objects = lo_objects
      io_identity = lo_identity ).

    DATA(ls_result) = lo_service->create(
      iv_name           = 'Demo-Repo'
      iv_description    = 'created by contract'
      iv_default_branch = 'main' ).

    cl_abap_unit_assert=>assert_true( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-repository-id
      exp = '00000000-0000-4000-8000-000000000001' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-repository-name
      exp = 'demo-repo' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-repository-default_branch
      exp = 'refs/heads/main' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-repository-version
      exp = 1 ).
    DATA(ls_read) = lo_metadata->zif_hithub_metadata_store~read_repository(
      ls_result-repository-id ).
    cl_abap_unit_assert=>assert_equals( act = ls_read-name exp = 'demo-repo' ).
    DATA(ls_reference) = lo_metadata->zif_hithub_metadata_store~read_reference(
      iv_repository_id = ls_result-repository-id
      iv_name          = 'refs/heads/main' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_reference-oid ).
    DATA(ls_commit_key) = VALUE zif_hithub_object_store=>ty_object_key(
      repository_id = ls_result-repository-id
      algorithm = 'sha1' oid = ls_reference-oid ).
    DATA(ls_commit_object) = lo_objects->zif_hithub_object_store~read(
      ls_commit_key ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_commit_object-type
      exp = 'commit' ).
    DATA(ls_commit) = zcl_hithub_commit_codec=>decode(
      ls_commit_object-payload ).
    DATA(ls_tree_key) = VALUE zif_hithub_object_store=>ty_object_key(
      repository_id = ls_result-repository-id
      algorithm = 'sha1' oid = ls_commit-tree ).
    DATA(ls_tree_object) = lo_objects->zif_hithub_object_store~read(
      ls_tree_key ).
    DATA(lt_entries) = zcl_hithub_tree_codec=>decode(
      ls_tree_object-payload ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_entries ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_entries[ 1 ]-name
      exp = 'README.md' ).
    DATA(ls_blob_key) = VALUE zif_hithub_object_store=>ty_object_key(
      repository_id = ls_result-repository-id
      algorithm = 'sha1' oid = lt_entries[ 1 ]-oid ).
    DATA(ls_blob_object) = lo_objects->zif_hithub_object_store~read(
      ls_blob_key ).
    lo_readme = cl_abap_conv_in_ce=>create(
      input = ls_blob_object-payload encoding = 'UTF-8' ).
    lo_readme->read( IMPORTING data = lv_readme ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_readme
      exp = '# demo-repo' && cl_abap_char_utilities=>newline ).
  ENDMETHOD.

  METHOD rejects_duplicate_name.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_identity) = NEW lcl_second_repository_identity( ).
    DATA(lo_service) = NEW zcl_hithub_repository_creation(
      io_metadata = lo_metadata io_transaction = lo_transaction
      io_objects = NEW zcl_hithub_local_object_store( )
      io_identity = lo_identity ).

    cl_abap_unit_assert=>assert_true(
      act = lo_service->create( iv_name = 'duplicate-repo' )-success ).
    DATA(ls_result) = lo_service->create( iv_name = 'DUPLICATE-REPO' ).
    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'repository already exists' ).
  ENDMETHOD.

  METHOD rejects_invalid_name.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_unit_work( ).
    DATA(lo_identity) = NEW lcl_repository_identity( ).
    DATA(lo_service) = NEW zcl_hithub_repository_creation(
      io_metadata = lo_metadata io_transaction = lo_transaction
      io_objects = NEW zcl_hithub_local_object_store( )
      io_identity = lo_identity ).
    DATA(ls_result) = lo_service->create( iv_name = 'bad name' ).

    cl_abap_unit_assert=>assert_false( act = ls_result-success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-reason
      exp = 'repository name is invalid' ).
  ENDMETHOD.

ENDCLASS.
