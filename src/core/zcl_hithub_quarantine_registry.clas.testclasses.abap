CLASS lcl_registry_quarantine DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_quarantine.
    METHODS discards RETURNING VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mv_discards TYPE i.

ENDCLASS.

CLASS lcl_registry_quarantine IMPLEMENTATION.

  METHOD zif_hithub_quarantine~stage.
    rv_staged = 0.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~promote.
    rv_promoted = 0.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~discard.
    mv_discards = mv_discards + 1.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~count.
    rv_count = 0.
  ENDMETHOD.

  METHOD discards.
    rv_count = mv_discards.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS cleans_abandoned_entries FOR TESTING RAISING cx_static_check.
    METHODS keeps_active_entries FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD cleans_abandoned_entries.
    DATA(lo_registry) = NEW zcl_hithub_quarantine_registry( ).
    DATA(lo_quarantine) = NEW lcl_registry_quarantine( ).

    ASSERT lo_registry->register(
      iv_id = 'abandoned' io_quarantine = lo_quarantine
      iv_last_activity = '20260827120000.0000000' ) = abap_true.
    ASSERT lo_registry->cleanup( '20260828120000.0000000' ) = 1.
    ASSERT lo_registry->count( ) = 0.
    ASSERT lo_quarantine->discards( ) = 1.
  ENDMETHOD.

  METHOD keeps_active_entries.
    DATA(lo_registry) = NEW zcl_hithub_quarantine_registry( ).
    DATA(lo_quarantine) = NEW lcl_registry_quarantine( ).

    ASSERT lo_registry->register(
      iv_id = 'active' io_quarantine = lo_quarantine
      iv_last_activity = '20260828130000.0000000' ) = abap_true.
    ASSERT lo_registry->cleanup( '20260828120000.0000000' ) = 0.
    ASSERT lo_registry->count( ) = 1.
    ASSERT lo_quarantine->discards( ) = 0.
  ENDMETHOD.

ENDCLASS.
