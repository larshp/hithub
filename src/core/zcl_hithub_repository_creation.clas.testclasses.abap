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
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_identity) = NEW lcl_repository_identity( ).
    DATA(lo_service) = NEW zcl_hithub_repository_creation(
      io_metadata = lo_metadata io_transaction = lo_transaction
      io_identity = lo_identity ).

    DATA(ls_result) = lo_service->create(
      iv_name = 'Demo-Repo'
      iv_description = 'created by contract'
      iv_default_branch = 'main' ).

    ASSERT ls_result-success = abap_true.
    ASSERT ls_result-repository-id =
      '00000000-0000-4000-8000-000000000001'.
    ASSERT ls_result-repository-name = 'demo-repo'.
    ASSERT ls_result-repository-default_branch = 'refs/heads/main'.
    ASSERT ls_result-repository-version = 1.
    DATA(ls_read) = lo_metadata->zif_hithub_metadata_store~read_repository(
      ls_result-repository-id ).
    ASSERT ls_read-name = 'demo-repo'.
  ENDMETHOD.

  METHOD rejects_duplicate_name.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_identity) = NEW lcl_repository_identity( ).
    DATA(lo_service) = NEW zcl_hithub_repository_creation(
      io_metadata = lo_metadata io_transaction = lo_transaction
      io_identity = lo_identity ).

    ASSERT lo_service->create( iv_name = 'duplicate-repo' )-success =
      abap_true.
    DATA(ls_result) = lo_service->create( iv_name = 'DUPLICATE-REPO' ).
    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'repository already exists'.
  ENDMETHOD.

  METHOD rejects_invalid_name.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_identity) = NEW lcl_repository_identity( ).
    DATA(lo_service) = NEW zcl_hithub_repository_creation(
      io_metadata = lo_metadata io_transaction = lo_transaction
      io_identity = lo_identity ).
    DATA(ls_result) = lo_service->create( iv_name = 'bad name' ).

    ASSERT ls_result-success = abap_false.
    ASSERT ls_result-reason = 'repository name is invalid'.
  ENDMETHOD.

ENDCLASS.
