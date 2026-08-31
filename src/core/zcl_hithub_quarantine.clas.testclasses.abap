CLASS lcl_quarantine_store DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_object_store.
    METHODS stored_count RETURNING VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mt_objects TYPE zif_hithub_quarantine=>ty_objects.

ENDCLASS.

CLASS lcl_quarantine_store IMPLEMENTATION.

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
    READ TABLE mt_objects TRANSPORTING NO FIELDS
      WITH KEY key-repository_id = is_object-key-repository_id
        key-algorithm = is_object-key-algorithm key-oid = is_object-key-oid.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND is_object TO mt_objects.
    rv_created = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_object_store~purge_repository.
    DELETE mt_objects WHERE key-repository_id = iv_repository_id.
    rv_purged = abap_true.
  ENDMETHOD.

  METHOD stored_count.
    rv_count = lines( mt_objects ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS promotes_staged_objects FOR TESTING RAISING cx_static_check.
    METHODS discards_without_promotion FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD promotes_staged_objects.
    DATA(lo_store) = NEW lcl_quarantine_store( ).
    DATA(lo_quarantine) = NEW zcl_hithub_quarantine( lo_store ).
    DATA lt_objects TYPE zif_hithub_quarantine=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    ls_object-key-repository_id = 'quarantine-repository'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = '1111111111111111111111111111111111111111'.
    ls_object-type = 'blob'.
    APPEND ls_object TO lt_objects.
    APPEND ls_object TO lt_objects.

    ASSERT lo_quarantine->zif_hithub_quarantine~stage( lt_objects ) = 1.
    ASSERT lo_quarantine->zif_hithub_quarantine~count( ) = 1.
    ASSERT lo_store->stored_count( ) = 0.
    ASSERT lo_quarantine->zif_hithub_quarantine~promote( ) = 1.
    ASSERT lo_store->stored_count( ) = 1.
    ASSERT lo_quarantine->zif_hithub_quarantine~count( ) = 0.
  ENDMETHOD.

  METHOD discards_without_promotion.
    DATA(lo_store) = NEW lcl_quarantine_store( ).
    DATA(lo_quarantine) = NEW zcl_hithub_quarantine( lo_store ).
    DATA lt_objects TYPE zif_hithub_quarantine=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    ls_object-key-repository_id = 'quarantine-repository'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = '2222222222222222222222222222222222222222'.
    APPEND ls_object TO lt_objects.
    lo_quarantine->zif_hithub_quarantine~stage( lt_objects ).
    lo_quarantine->zif_hithub_quarantine~discard( ).

    ASSERT lo_quarantine->zif_hithub_quarantine~count( ) = 0.
    ASSERT lo_store->stored_count( ) = 0.
  ENDMETHOD.

ENDCLASS.
