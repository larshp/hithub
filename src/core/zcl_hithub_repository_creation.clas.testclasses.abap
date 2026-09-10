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

    "! create( ) commits, and both fixtures below use a fixed name, so a
    "! repository left behind by an earlier run makes the name unavailable
    "! for good. Report that here rather than as a bare create failure.
    METHODS assert_name_is_free
      IMPORTING
        io_metadata TYPE REF TO zif_hithub_metadata_store
        iv_name     TYPE string
      RAISING
        cx_static_check.

ENDCLASS.

CLASS ltcl_repository_creation IMPLEMENTATION.

  METHOD assert_name_is_free.
    DATA ls_existing TYPE zif_hithub_metadata_store=>ty_repository.
    DATA lv_existing_name TYPE string.

    LOOP AT io_metadata->list_repositories( ) INTO ls_existing.
      lv_existing_name = ls_existing-name.
      TRANSLATE lv_existing_name TO LOWER CASE.
      cl_abap_unit_assert=>assert_differs(
        act = lv_existing_name
        exp = iv_name
        msg = |{ iv_name } was left behind by an earlier committed run| ).
    ENDLOOP.
  ENDMETHOD.

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

    assert_name_is_free( io_metadata = lo_metadata iv_name = 'demo-repo' ).
    DATA(ls_result) = lo_service->create(
      iv_name           = 'Demo-Repo'
      iv_description    = 'created by contract'
      iv_default_branch = 'main' ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_result-reason
      msg = 'the repository could not be created' ).
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
      algorithm     = 'sha1'
      oid           = zcl_hithub_object_id=>from_bytes(
        lt_entries[ 1 ]-oid ) ).
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

    assert_name_is_free(
      io_metadata = lo_metadata iv_name = 'duplicate-repo' ).
    DATA(ls_first) = lo_service->create( iv_name = 'duplicate-repo' ).
    cl_abap_unit_assert=>assert_initial(
      act = ls_first-reason
      msg = 'the first repository could not be created' ).
    cl_abap_unit_assert=>assert_true( act = ls_first-success ).
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
