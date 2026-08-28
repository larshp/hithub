CLASS ltcl_garbage_collector DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS deletes_unreachable_objects FOR TESTING RAISING cx_static_check.
    METHODS protects_active_quarantine FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_garbage_collector IMPLEMENTATION.

  METHOD deletes_unreachable_objects.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA ls_reachable TYPE zif_hithub_object_store=>ty_object.
    DATA ls_orphan TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_reachable_oid TYPE string.
    DATA lv_orphan_oid TYPE string.
    DATA(lv_repository_id) = 'gc-repository-000000000000000000'.

    ls_reachable-key-repository_id = lv_repository_id.
    ls_reachable-key-algorithm = 'sha1'.
    ls_reachable-type = 'blob'.
    ls_reachable-payload = cl_abap_codepage=>convert_to( 'reachable' ).
    ls_reachable-size = xstrlen( ls_reachable-payload ).
    lv_reachable_oid = zcl_hithub_object_id=>calculate(
      iv_type = ls_reachable-type iv_payload = ls_reachable-payload ).
    ls_reachable-key-oid = lv_reachable_oid.
    ASSERT lo_store->zif_hithub_object_store~write( ls_reachable ) = abap_true.

    ls_orphan = ls_reachable.
    ls_orphan-payload = cl_abap_codepage=>convert_to( 'orphan' ).
    ls_orphan-size = xstrlen( ls_orphan-payload ).
    lv_orphan_oid = zcl_hithub_object_id=>calculate(
      iv_type = ls_orphan-type iv_payload = ls_orphan-payload ).
    ls_orphan-key-oid = lv_orphan_oid.
    ASSERT lo_store->zif_hithub_object_store~write( ls_orphan ) = abap_true.

    ls_reference-repository_id = lv_repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_reachable_oid.
    ASSERT lo_metadata->zif_hithub_metadata_store~create_reference(
      ls_reference ) = 1.

    DATA(lo_collector) = NEW zcl_hithub_garbage_collector(
      io_store = lo_store io_metadata = lo_metadata io_gc = lo_store ).
    ASSERT lo_collector->collect( lv_repository_id ) = 1.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_reachable-key ) =
      abap_true.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_orphan-key ) =
      abap_false.
  ENDMETHOD.

  METHOD protects_active_quarantine.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_quarantine) = NEW zcl_hithub_quarantine( lo_store ).
    DATA ls_protected TYPE zif_hithub_object_store=>ty_object.
    DATA ls_orphan TYPE zif_hithub_object_store=>ty_object.
    DATA lt_objects TYPE zif_hithub_quarantine=>ty_objects.
    DATA lv_protected_oid TYPE string.
    DATA lv_orphan_oid TYPE string.
    DATA(lv_repository_id) = 'gc-quarantine-repository-0000000'.

    ls_protected-key-repository_id = lv_repository_id.
    ls_protected-key-algorithm = 'sha1'.
    ls_protected-type = 'blob'.
    ls_protected-payload = cl_abap_codepage=>convert_to( 'active quarantine' ).
    ls_protected-size = xstrlen( ls_protected-payload ).
    lv_protected_oid = zcl_hithub_object_id=>calculate(
      iv_type = ls_protected-type iv_payload = ls_protected-payload ).
    ls_protected-key-oid = lv_protected_oid.
    ASSERT lo_store->zif_hithub_object_store~write( ls_protected ) = abap_true.
    APPEND ls_protected TO lt_objects.
    ASSERT lo_quarantine->zif_hithub_quarantine~stage( lt_objects ) = 1.

    ls_orphan = ls_protected.
    ls_orphan-payload = cl_abap_codepage=>convert_to( 'unprotected orphan' ).
    ls_orphan-size = xstrlen( ls_orphan-payload ).
    lv_orphan_oid = zcl_hithub_object_id=>calculate(
      iv_type = ls_orphan-type iv_payload = ls_orphan-payload ).
    ls_orphan-key-oid = lv_orphan_oid.
    ASSERT lo_store->zif_hithub_object_store~write( ls_orphan ) = abap_true.

    DATA(lo_collector) = NEW zcl_hithub_garbage_collector(
      io_store = lo_store io_metadata = lo_metadata io_gc = lo_store
      io_roots = lo_quarantine ).
    ASSERT lo_collector->collect( lv_repository_id ) = 1.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_protected-key ) =
      abap_true.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_orphan-key ) =
      abap_false.
    ASSERT lo_quarantine->zif_hithub_quarantine~count( ) = 1.
  ENDMETHOD.

ENDCLASS.
