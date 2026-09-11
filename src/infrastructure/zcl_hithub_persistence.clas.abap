CLASS zcl_hithub_persistence DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS c_sap TYPE string VALUE 'sap'.
    CONSTANTS c_open_abap TYPE string VALUE 'open-abap'.

    "! Chooses the persistence adapters the ICF handler runs on. SAP is the
    "! default because that is where an installed service runs: its repository
    "! lock uses the enqueue server and its asset store reads the MIME
    "! repository. The open-abap deployment has to opt out through
    "! use_open_abap, because it holds the repository lock in process memory
    "! and only serialises callers inside one work process.
    CLASS-METHODS use_sap.

    CLASS-METHODS use_open_abap.

    CLASS-METHODS mode
      RETURNING
        VALUE(rv_mode) TYPE string.

    CLASS-METHODS metadata_store
      RETURNING
        VALUE(ro_store) TYPE REF TO zif_hithub_metadata_store.

    CLASS-METHODS object_store
      RETURNING
        VALUE(ro_store) TYPE REF TO zif_hithub_object_store.

    CLASS-METHODS transaction
      RETURNING
        VALUE(ro_transaction) TYPE REF TO zif_hithub_transaction.

    CLASS-METHODS repository_lock
      RETURNING
        VALUE(ro_lock) TYPE REF TO zif_hithub_repository_lock.

    CLASS-METHODS event_sink
      RETURNING
        VALUE(ro_sink) TYPE REF TO zif_hithub_event_sink.

    "! The browser assets follow the same deployment switch: an installed
    "! service reads the MIME objects abapGit deserialized, the local runtime
    "! reads what it registered from the serialized SMIM files at startup.
    CLASS-METHODS asset_store
      RETURNING
        VALUE(ro_store) TYPE REF TO zif_hithub_asset_store.

  PRIVATE SECTION.
    CLASS-DATA gv_mode TYPE string.
ENDCLASS.

CLASS zcl_hithub_persistence IMPLEMENTATION.

  METHOD use_sap.
    gv_mode = c_sap.
  ENDMETHOD.

  METHOD use_open_abap.
    gv_mode = c_open_abap.
  ENDMETHOD.

  METHOD mode.
    IF gv_mode = c_open_abap.
      rv_mode = c_open_abap.
    ELSE.
      rv_mode = c_sap.
    ENDIF.
  ENDMETHOD.

  METHOD metadata_store.
    IF mode( ) = c_open_abap.
      ro_store = NEW zcl_hithub_local_meta_store( ).
    ELSE.
      ro_store = NEW zcl_hithub_sap_meta_store( ).
    ENDIF.
  ENDMETHOD.

  METHOD object_store.
    IF mode( ) = c_open_abap.
      ro_store = NEW zcl_hithub_local_object_store( ).
    ELSE.
      ro_store = NEW zcl_hithub_sap_object_store( ).
    ENDIF.
  ENDMETHOD.

  METHOD transaction.
    " COMMIT WORK and ROLLBACK WORK end the LUW in both runtimes, so the unit
    " of work is the same class everywhere and there is nothing to vary here.
    ro_transaction = NEW zcl_hithub_unit_work( ).
  ENDMETHOD.

  METHOD repository_lock.
    IF mode( ) = c_open_abap.
      ro_lock = NEW zcl_hithub_local_repo_lock( ).
    ELSE.
      ro_lock = NEW zcl_hithub_sap_repo_lock( ).
    ENDIF.
  ENDMETHOD.

  METHOD event_sink.
    " The event sink writes ZHI_EVENT through Open SQL, which both runtimes
    " support, so there is nothing to vary here.
    ro_sink = NEW zcl_hithub_local_event_sink( ).
  ENDMETHOD.

  METHOD asset_store.
    IF mode( ) = c_open_abap.
      ro_store = NEW zcl_hithub_local_asset_store( ).
    ELSE.
      ro_store = NEW zcl_hithub_sap_asset_store( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
