CLASS ltcl_merge_persist DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_object_before_ref FOR TESTING RAISING cx_static_check.
    METHODS rolls_back_on_ref_failure FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_persist IMPLEMENTATION.

  METHOD writes_object_before_ref.
    DATA lo_store TYPE REF TO zif_hithub_object_store.
    DATA lo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA lo_transaction TYPE REF TO zif_hithub_transaction.
    DATA lo_persist TYPE REF TO zcl_hithub_merge_persist.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.
    lv_payload = cl_abap_codepage=>convert_to( 'merged tree object' ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ls_object-key-repository_id = 'merge-persist-repository-1'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = lv_oid.
    ls_object-type = 'blob'.
    ls_object-size = xstrlen( lv_payload ).
    ls_object-payload = lv_payload.
    ls_reference-repository_id = ls_object-key-repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_oid.
    lo_store = NEW zcl_hithub_local_object_store( ).
    lo_metadata = NEW zcl_hithub_local_meta_store( ).
    lo_transaction = NEW zcl_hithub_local_unit_work( ).
    lo_persist = NEW zcl_hithub_merge_persist(
      io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction ).

    ASSERT lo_persist->apply(
      is_object = ls_object is_reference = ls_reference ) = abap_true.
    ASSERT lo_store->contains( ls_object-key ) = abap_true.
    ASSERT lo_metadata->read_reference(
      iv_repository_id = ls_reference-repository_id
      iv_name          = ls_reference-name )-oid = lv_oid.
  ENDMETHOD.

  METHOD rolls_back_on_ref_failure.
    DATA lo_store TYPE REF TO zif_hithub_object_store.
    DATA lo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA lo_transaction TYPE REF TO zif_hithub_transaction.
    DATA lo_persist TYPE REF TO zcl_hithub_merge_persist.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.
    lv_payload = cl_abap_codepage=>convert_to( 'rolled back merge object' ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    ls_object-key-repository_id = 'merge-persist-repository-2'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = lv_oid.
    ls_object-type = 'blob'.
    ls_object-size = xstrlen( lv_payload ).
    ls_object-payload = lv_payload.
    ls_reference-repository_id = ls_object-key-repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_oid.
    lo_store = NEW zcl_hithub_local_object_store( ).
    lo_metadata = NEW zcl_hithub_local_meta_store( ).
    lo_transaction = NEW zcl_hithub_local_unit_work( ).
    lo_persist = NEW zcl_hithub_merge_persist(
      io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction ).

    ASSERT lo_persist->apply(
      is_object = ls_object is_reference = ls_reference
      iv_expected_version = 9 ) = abap_false.
    ASSERT lo_store->contains( ls_object-key ) = abap_false.
  ENDMETHOD.

ENDCLASS.
