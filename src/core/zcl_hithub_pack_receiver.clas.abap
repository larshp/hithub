CLASS zcl_hithub_pack_receiver DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_codec      TYPE REF TO zcl_hithub_pack_codec
        io_store      TYPE REF TO zif_hithub_object_store
        io_metadata   TYPE REF TO zif_hithub_metadata_store
        io_transaction TYPE REF TO zif_hithub_transaction.

    METHODS receive
      IMPORTING
        iv_pack              TYPE xstring
        iv_repository_id    TYPE string
        iv_ref_name         TYPE string
        iv_target_oid       TYPE string
        iv_algorithm        TYPE string DEFAULT 'sha1'
        iv_expected_version TYPE int8 OPTIONAL
      RETURNING
        VALUE(rv_updated) TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_codec TYPE REF TO zcl_hithub_pack_codec.
    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.

ENDCLASS.

CLASS zcl_hithub_pack_receiver IMPLEMENTATION.

  METHOD constructor.
    mo_codec = io_codec.
    mo_store = io_store.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD receive.
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_version TYPE int8.

    CLEAR rv_updated.
    IF mo_codec IS INITIAL OR mo_store IS INITIAL
        OR mo_metadata IS INITIAL OR mo_transaction IS INITIAL.
      RETURN.
    ENDIF.
    IF zcl_hithub_ref_validator=>is_valid( iv_ref_name ) = abap_false
        OR zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = iv_algorithm iv_oid = iv_target_oid ) = abap_false.
      RETURN.
    ENDIF.

    lt_objects = mo_codec->unpack(
      iv_pack = iv_pack
      iv_repository_id = iv_repository_id
      iv_algorithm = iv_algorithm ).
    IF lt_objects IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE lt_objects INTO ls_object
      WITH KEY key-repository_id = iv_repository_id
        key-algorithm = iv_algorithm key-oid = iv_target_oid.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    mo_transaction->start( ).
    DATA(lo_ingestor) = NEW zcl_hithub_pack_ingestor( mo_store ).
    lo_ingestor->ingest( lt_objects ).

    ls_reference-repository_id = iv_repository_id.
    ls_reference-name = iv_ref_name.
    ls_reference-algorithm = iv_algorithm.
    ls_reference-oid = iv_target_oid.
    lv_version = mo_metadata->save_reference(
      is_reference = ls_reference
      iv_expected_version = iv_expected_version ).
    IF lv_version IS INITIAL.
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.

    mo_transaction->commit( ).
    rv_updated = abap_true.
  ENDMETHOD.

ENDCLASS.
