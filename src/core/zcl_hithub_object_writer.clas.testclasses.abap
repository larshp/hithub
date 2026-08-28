CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS refuses_replacement FOR TESTING RAISING cx_static_check.
    METHODS rejects_malformed_object FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD refuses_replacement.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_writer) = NEW zcl_hithub_object_writer( lo_store ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_created TYPE abap_bool.

    ls_object-key-repository_id = 'writer-contract-repository-0000000'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'.
    ls_object-type = 'blob'.
    ls_object-size = 5.
    ls_object-payload = cl_abap_codepage=>convert_to( 'hello' ).
    lv_created = lo_writer->write( ls_object ).
    ASSERT lv_created = abap_true.
    lv_created = lo_writer->write( ls_object ).
    ASSERT lv_created = abap_false.
  ENDMETHOD.

  METHOD rejects_malformed_object.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_writer) = NEW zcl_hithub_object_writer( lo_store ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_created TYPE abap_bool.

    ls_object-key-repository_id = 'writer-invalid-repository-000000'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'.
    ls_object-type = 'blob'.
    ls_object-size = 4.
    ls_object-payload = cl_abap_codepage=>convert_to( 'hello' ).

    lv_created = lo_writer->write( ls_object ).

    ASSERT lv_created = abap_false.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_object-key ) = abap_false.
  ENDMETHOD.

ENDCLASS.
