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
    METHODS serves_the_asset_store FOR TESTING RAISING cx_static_check.

    CLASS-METHODS is_unit_work
      IMPORTING
        io_transaction      TYPE REF TO zif_hithub_transaction
      RETURNING
        VALUE(rv_unit_work) TYPE abap_bool.

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

  METHOD is_unit_work.
    DATA lo_unit_work TYPE REF TO zcl_hithub_unit_work.
    CLEAR rv_unit_work.
    TRY.
        lo_unit_work ?= io_transaction.
        rv_unit_work = xsdbool( lo_unit_work IS BOUND ).
      CATCH cx_sy_move_cast_error.
        CLEAR rv_unit_work.
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
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_persistence=>mode( )
      exp = zcl_hithub_persistence=>c_sap ).
    zcl_hithub_persistence=>use_open_abap( ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_persistence=>mode( )
      exp = zcl_hithub_persistence=>c_open_abap ).
    zcl_hithub_persistence=>use_sap( ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_persistence=>mode( )
      exp = zcl_hithub_persistence=>c_sap ).
  ENDMETHOD.

  METHOD serves_sap_adapters.
    zcl_hithub_persistence=>use_sap( ).
    cl_abap_unit_assert=>assert_true(
      act = is_unit_work(
        zcl_hithub_persistence=>transaction( ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = is_sap_lock(
        zcl_hithub_persistence=>repository_lock( ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = is_sap_metadata_store(
        zcl_hithub_persistence=>metadata_store( ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = is_sap_object_store(
        zcl_hithub_persistence=>object_store( ) ) ).
  ENDMETHOD.

  METHOD serves_open_abap_adapters.
    zcl_hithub_persistence=>use_open_abap( ).
    " The unit of work does not vary: COMMIT WORK and ROLLBACK WORK end the
    " LUW in both runtimes, so both modes serve the same class.
    cl_abap_unit_assert=>assert_true(
      act = is_unit_work(
        zcl_hithub_persistence=>transaction( ) ) ).
    cl_abap_unit_assert=>assert_false(
      act = is_sap_lock(
        zcl_hithub_persistence=>repository_lock( ) ) ).
    cl_abap_unit_assert=>assert_false(
      act = is_sap_metadata_store(
        zcl_hithub_persistence=>metadata_store( ) ) ).
    cl_abap_unit_assert=>assert_false(
      act = is_sap_object_store(
        zcl_hithub_persistence=>object_store( ) ) ).
    cl_abap_unit_assert=>assert_bound(
      act = zcl_hithub_persistence=>transaction( ) ).
    cl_abap_unit_assert=>assert_bound(
      act = zcl_hithub_persistence=>repository_lock( ) ).
  ENDMETHOD.

  METHOD shares_the_event_sink.
    zcl_hithub_persistence=>use_sap( ).
    cl_abap_unit_assert=>assert_bound(
      act = zcl_hithub_persistence=>event_sink( ) ).
    zcl_hithub_persistence=>use_open_abap( ).
    cl_abap_unit_assert=>assert_bound(
      act = zcl_hithub_persistence=>event_sink( ) ).
  ENDMETHOD.

  METHOD serves_the_asset_store.
    DATA lo_sap TYPE REF TO zcl_hithub_sap_asset_store.

    " An installed service has to read the MIME repository, because that is
    " where abapGit put the browser assets; the local runtime never can.
    zcl_hithub_persistence=>use_sap( ).
    lo_sap ?= zcl_hithub_persistence=>asset_store( ).
    cl_abap_unit_assert=>assert_bound( act = lo_sap ).
    zcl_hithub_persistence=>use_open_abap( ).
    CLEAR lo_sap.
    TRY.
        lo_sap ?= zcl_hithub_persistence=>asset_store( ).
      CATCH cx_sy_move_cast_error.
        CLEAR lo_sap.
    ENDTRY.
    cl_abap_unit_assert=>assert_not_bound( act = lo_sap ).
    cl_abap_unit_assert=>assert_bound(
      act = zcl_hithub_persistence=>asset_store( ) ).
  ENDMETHOD.

ENDCLASS.
