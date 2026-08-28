CLASS lcl_receive_target_store DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_object_store.
    METHODS add IMPORTING is_object TYPE zif_hithub_object_store=>ty_object.

  PRIVATE SECTION.
    DATA mt_objects TYPE zif_hithub_quarantine=>ty_objects.

ENDCLASS.

CLASS lcl_receive_target_store IMPLEMENTATION.

  METHOD add.
    APPEND is_object TO mt_objects.
  ENDMETHOD.

  METHOD zif_hithub_object_store~read.
    READ TABLE mt_objects INTO rs_object
      WITH KEY key-repository_id = is_key-repository_id
        key-algorithm = is_key-algorithm key-oid = is_key-oid.
  ENDMETHOD.

  METHOD zif_hithub_object_store~contains.
    READ TABLE mt_objects TRANSPORTING NO FIELDS
      WITH KEY key-repository_id = is_key-repository_id
        key-algorithm = is_key-algorithm key-oid = is_key-oid.
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_object_store~write.
    APPEND is_object TO mt_objects.
    rv_created = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_object_store~purge_repository.
    DELETE mt_objects WHERE key-repository_id = iv_repository_id.
    rv_purged = abap_true.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS accepts_branch_commit FOR TESTING RAISING cx_static_check.
    METHODS rejects_branch_blob FOR TESTING RAISING cx_static_check.
    METHODS accepts_annotated_tag FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_ref_name FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD accepts_branch_commit.
    DATA(lo_store) = NEW lcl_receive_target_store( ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.

    ls_key-repository_id = 'target-repository'.
    ls_key-algorithm = 'sha1'.
    ls_key-oid = '1111111111111111111111111111111111111111'.
    ls_object-key = ls_key.
    ls_object-type = 'commit'.
    lo_store->add( ls_object ).
    ASSERT zcl_hithub_receive_target=>is_valid_target(
      io_store = lo_store is_key = ls_key iv_ref_name = 'refs/heads/main' ) =
      abap_true.
  ENDMETHOD.

  METHOD rejects_branch_blob.
    DATA(lo_store) = NEW lcl_receive_target_store( ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.

    ls_key-repository_id = 'target-repository'.
    ls_key-algorithm = 'sha1'.
    ls_key-oid = '2222222222222222222222222222222222222222'.
    ls_object-key = ls_key.
    ls_object-type = 'blob'.
    lo_store->add( ls_object ).
    ASSERT zcl_hithub_receive_target=>is_valid_target(
      io_store = lo_store is_key = ls_key iv_ref_name = 'refs/heads/main' ) =
      abap_false.
  ENDMETHOD.

  METHOD accepts_annotated_tag.
    DATA(lo_store) = NEW lcl_receive_target_store( ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.

    ls_key-repository_id = 'target-repository'.
    ls_key-algorithm = 'sha1'.
    ls_key-oid = '3333333333333333333333333333333333333333'.
    ls_object-key = ls_key.
    ls_object-type = 'tag'.
    lo_store->add( ls_object ).
    ASSERT zcl_hithub_receive_target=>is_valid_target(
      io_store = lo_store is_key = ls_key iv_ref_name = 'refs/tags/v2' ) =
      abap_true.
  ENDMETHOD.

  METHOD rejects_bad_ref_name.
    DATA(lo_store) = NEW lcl_receive_target_store( ).
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.

    ls_key-repository_id = 'target-repository'.
    ls_key-algorithm = 'sha1'.
    ls_key-oid = '1111111111111111111111111111111111111111'.
    ASSERT zcl_hithub_receive_target=>is_valid_target(
      io_store = lo_store is_key = ls_key iv_ref_name = 'refs/heads/a b' ) =
      abap_false.
  ENDMETHOD.

ENDCLASS.
