CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS deduplicates_pack_objects FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD deduplicates_pack_objects.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_ingestor) = NEW zcl_hithub_pack_ingestor( lo_store ).
    DATA lt_objects TYPE zcl_hithub_pack_ingestor=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    ls_object-key-repository_id = 'pack-ingest-repository-000000000'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'.
    ls_object-type = 'blob'.
    ls_object-size = 5.
    ls_object-payload = cl_abap_codepage=>convert_to( 'hello' ).
    APPEND ls_object TO lt_objects.
    APPEND ls_object TO lt_objects.

    ASSERT lo_ingestor->ingest( lt_objects ) = 1.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_object-key ) = abap_true.
  ENDMETHOD.

ENDCLASS.
