CLASS zcl_hithub_merge_persist DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_store       TYPE REF TO zif_hithub_object_store
        io_metadata    TYPE REF TO zif_hithub_metadata_store
        io_transaction TYPE REF TO zif_hithub_transaction.

    METHODS apply
      IMPORTING
        is_object           TYPE zif_hithub_object_store=>ty_object
        is_reference        TYPE zif_hithub_metadata_store=>ty_reference
        iv_expected_version TYPE int8 OPTIONAL
      RETURNING
        VALUE(rv_applied)   TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
ENDCLASS.

CLASS zcl_hithub_merge_persist IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD apply.
    DATA lo_writer TYPE REF TO zcl_hithub_object_writer.
    DATA lv_version TYPE int8.

    CLEAR rv_applied.
    IF mo_store IS INITIAL OR mo_metadata IS INITIAL
        OR mo_transaction IS INITIAL.
      RETURN.
    ENDIF.
    mo_transaction->start( ).
    lo_writer = NEW zcl_hithub_object_writer( mo_store ).
    IF lo_writer->write( is_object ) = abap_false
        AND mo_store->contains( is_object-key ) = abap_false.
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.
    lv_version = mo_metadata->save_reference(
      is_reference = is_reference iv_expected_version = iv_expected_version ).
    IF lv_version IS INITIAL.
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.
    mo_transaction->commit( ).
    rv_applied = abap_true.
  ENDMETHOD.

ENDCLASS.
