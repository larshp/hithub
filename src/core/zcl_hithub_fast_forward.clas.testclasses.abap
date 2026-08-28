CLASS lcl_fast_forward_store DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_object_store.
    METHODS constructor
      IMPORTING it_objects TYPE zif_hithub_quarantine=>ty_objects OPTIONAL.

  PRIVATE SECTION.
    DATA mt_objects TYPE zif_hithub_quarantine=>ty_objects.

ENDCLASS.

CLASS lcl_fast_forward_store IMPLEMENTATION.

  METHOD constructor.
    mt_objects = it_objects.
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
    METHODS allows_creation FOR TESTING RAISING cx_static_check.
    METHODS allows_ancestor_update FOR TESTING RAISING cx_static_check.
    METHODS rejects_non_ancestor FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD allows_creation.
    DATA(lo_store) = NEW lcl_fast_forward_store( ).
    DATA(lo_reader) = NEW zcl_hithub_object_reader( lo_store ).
    DATA(lo_reachability) = NEW zcl_hithub_reachability( lo_reader ).
    DATA ls_old TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_new TYPE zif_hithub_object_store=>ty_object_key.

    ls_old-repository_id = 'fast-forward-repository'.
    ls_old-algorithm = 'sha1'.
    ls_old-oid = '0000000000000000000000000000000000000000'.
    ls_new = ls_old.
    ls_new-oid = '1111111111111111111111111111111111111111'.
    ASSERT zcl_hithub_fast_forward=>allows_update(
      io_reachability = lo_reachability is_old = ls_old is_new = ls_new ) =
      abap_true.
  ENDMETHOD.

  METHOD allows_ancestor_update.
    DATA lt_objects TYPE zif_hithub_quarantine=>ty_objects.
    DATA ls_old_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_new_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA lv_old_oid TYPE string.
    DATA lv_new_oid TYPE string.
    DATA ls_old TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_new TYPE zif_hithub_object_store=>ty_object_key.

    ls_commit-tree = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'.
    ls_commit-author = 'Author <author@example.invalid> 1704067200 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = 'old' && cl_abap_char_utilities=>newline.
    ls_old_object-type = 'commit'.
    ls_old_object-key-repository_id = 'fast-forward-repository'.
    ls_old_object-key-algorithm = 'sha1'.
    ls_old_object-payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    lv_old_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = ls_old_object-payload ).
    ls_old_object-key-oid = lv_old_oid.
    APPEND ls_old_object TO lt_objects.

    ls_commit-parents = VALUE #( ( lv_old_oid ) ).
    ls_commit-message = 'new' && cl_abap_char_utilities=>newline.
    ls_new_object = ls_old_object.
    ls_new_object-payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    lv_new_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = ls_new_object-payload ).
    ls_new_object-key-oid = lv_new_oid.
    APPEND ls_new_object TO lt_objects.

    DATA(lo_store) = NEW lcl_fast_forward_store( lt_objects ).
    DATA(lo_reader) = NEW zcl_hithub_object_reader( lo_store ).
    DATA(lo_reachability) = NEW zcl_hithub_reachability( lo_reader ).
    ls_old = ls_old_object-key.
    ls_new = ls_new_object-key.
    ASSERT zcl_hithub_fast_forward=>allows_update(
      io_reachability = lo_reachability is_old = ls_old is_new = ls_new ) =
      abap_true.
  ENDMETHOD.

  METHOD rejects_non_ancestor.
    DATA(lo_store) = NEW lcl_fast_forward_store( ).
    DATA(lo_reader) = NEW zcl_hithub_object_reader( lo_store ).
    DATA(lo_reachability) = NEW zcl_hithub_reachability( lo_reader ).
    DATA ls_old TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_new TYPE zif_hithub_object_store=>ty_object_key.

    ls_old-repository_id = 'fast-forward-repository'.
    ls_old-algorithm = 'sha1'.
    ls_old-oid = '1111111111111111111111111111111111111111'.
    ls_new = ls_old.
    ls_new-oid = '2222222222222222222222222222222222222222'.
    ASSERT zcl_hithub_fast_forward=>allows_update(
      io_reachability = lo_reachability is_old = ls_old is_new = ls_new ) =
      abap_false.
  ENDMETHOD.

ENDCLASS.
