CLASS ltcl_persistence DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS defaults_to_sap FOR TESTING RAISING cx_static_check.
    METHODS serves_sap_adapters FOR TESTING RAISING cx_static_check.
    METHODS serves_open_abap_adapters FOR TESTING RAISING cx_static_check.
    METHODS shares_the_event_sink FOR TESTING RAISING cx_static_check.

    CLASS-METHODS is_sap_transaction
      IMPORTING
        io_transaction TYPE REF TO zif_hithub_transaction
      RETURNING
        VALUE(rv_sap)  TYPE abap_bool.

    CLASS-METHODS is_sap_lock
      IMPORTING
        io_lock       TYPE REF TO zif_hithub_repository_lock
      RETURNING
        VALUE(rv_sap) TYPE abap_bool.

    CLASS-METHODS is_sap_metadata_store
      IMPORTING
        io_store      TYPE REF TO zif_hithub_metadata_store
      RETURNING
        VALUE(rv_sap) TYPE abap_bool.

    CLASS-METHODS is_sap_object_store
      IMPORTING
        io_store      TYPE REF TO zif_hithub_object_store
      RETURNING
        VALUE(rv_sap) TYPE abap_bool.
ENDCLASS.

CLASS ltcl_persistence IMPLEMENTATION.

  METHOD teardown.
    " The mode is class data, so leave the default in place for other tests.
    zcl_hithub_persistence=>use_sap( ).
  ENDMETHOD.

  METHOD is_sap_transaction.
    DATA lo_sap TYPE REF TO zcl_hithub_sap_unit_work.
    CLEAR rv_sap.
    TRY.
        lo_sap ?= io_transaction.
        rv_sap = xsdbool( lo_sap IS BOUND ).
      CATCH cx_sy_move_cast_error.
        CLEAR rv_sap.
    ENDTRY.
  ENDMETHOD.

  METHOD is_sap_lock.
    DATA lo_sap TYPE REF TO zcl_hithub_sap_repo_lock.
    CLEAR rv_sap.
    TRY.
        lo_sap ?= io_lock.
        rv_sap = xsdbool( lo_sap IS BOUND ).
      CATCH cx_sy_move_cast_error.
        CLEAR rv_sap.
    ENDTRY.
  ENDMETHOD.

  METHOD is_sap_metadata_store.
    DATA lo_sap TYPE REF TO zcl_hithub_sap_meta_store.
    CLEAR rv_sap.
    TRY.
        lo_sap ?= io_store.
        rv_sap = xsdbool( lo_sap IS BOUND ).
      CATCH cx_sy_move_cast_error.
        CLEAR rv_sap.
    ENDTRY.
  ENDMETHOD.

  METHOD is_sap_object_store.
    DATA lo_sap TYPE REF TO zcl_hithub_sap_object_store.
    CLEAR rv_sap.
    TRY.
        lo_sap ?= io_store.
        rv_sap = xsdbool( lo_sap IS BOUND ).
      CATCH cx_sy_move_cast_error.
        CLEAR rv_sap.
    ENDTRY.
  ENDMETHOD.

  METHOD defaults_to_sap.
    " An installed ICF service configures nothing, so the untouched default has
    " to be the SAP adapter set.
    ASSERT zcl_hithub_persistence=>mode( ) = zcl_hithub_persistence=>c_sap.
    zcl_hithub_persistence=>use_open_abap( ).
    ASSERT zcl_hithub_persistence=>mode( ) = zcl_hithub_persistence=>c_open_abap.
    zcl_hithub_persistence=>use_sap( ).
    ASSERT zcl_hithub_persistence=>mode( ) = zcl_hithub_persistence=>c_sap.
  ENDMETHOD.

  METHOD serves_sap_adapters.
    zcl_hithub_persistence=>use_sap( ).
    ASSERT is_sap_transaction(
      zcl_hithub_persistence=>transaction( ) ) = abap_true.
    ASSERT is_sap_lock(
      zcl_hithub_persistence=>repository_lock( ) ) = abap_true.
    ASSERT is_sap_metadata_store(
      zcl_hithub_persistence=>metadata_store( ) ) = abap_true.
    ASSERT is_sap_object_store(
      zcl_hithub_persistence=>object_store( ) ) = abap_true.
  ENDMETHOD.

  METHOD serves_open_abap_adapters.
    zcl_hithub_persistence=>use_open_abap( ).
    ASSERT is_sap_transaction(
      zcl_hithub_persistence=>transaction( ) ) = abap_false.
    ASSERT is_sap_lock(
      zcl_hithub_persistence=>repository_lock( ) ) = abap_false.
    ASSERT is_sap_metadata_store(
      zcl_hithub_persistence=>metadata_store( ) ) = abap_false.
    ASSERT is_sap_object_store(
      zcl_hithub_persistence=>object_store( ) ) = abap_false.
    ASSERT zcl_hithub_persistence=>transaction( ) IS BOUND.
    ASSERT zcl_hithub_persistence=>repository_lock( ) IS BOUND.
  ENDMETHOD.

  METHOD shares_the_event_sink.
    zcl_hithub_persistence=>use_sap( ).
    ASSERT zcl_hithub_persistence=>event_sink( ) IS BOUND.
    zcl_hithub_persistence=>use_open_abap( ).
    ASSERT zcl_hithub_persistence=>event_sink( ) IS BOUND.
  ENDMETHOD.

ENDCLASS.
