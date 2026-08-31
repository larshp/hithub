CLASS zcl_hithub_merge_target DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_lock          TYPE REF TO zif_hithub_repository_lock
        io_metadata      TYPE REF TO zif_hithub_metadata_store
        iv_repository_id TYPE string
        iv_owner         TYPE string.

    METHODS check
      IMPORTING
        iv_ref_name       TYPE string
        iv_algorithm      TYPE string
        iv_expected_oid   TYPE string
      RETURNING
        VALUE(rv_matches) TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_lock TYPE REF TO zcl_hithub_merge_lock.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mv_repository_id TYPE string.
  
ENDCLASS.

CLASS zcl_hithub_merge_target IMPLEMENTATION.

  METHOD constructor.
    mo_lock = NEW zcl_hithub_merge_lock(
      io_lock = io_lock iv_repository_id = iv_repository_id
      iv_owner = iv_owner ).
    mo_metadata = io_metadata.
    mv_repository_id = iv_repository_id.
  ENDMETHOD.

  METHOD check.
    CLEAR rv_matches.
    IF mo_lock IS INITIAL OR mo_metadata IS INITIAL
        OR mo_lock->acquire( ) = abap_false.
      RETURN.
    ENDIF.
    rv_matches = zcl_hithub_ref_update_policy=>old_oid_matches(
      io_metadata = mo_metadata iv_repository_id = mv_repository_id
      iv_ref_name = iv_ref_name iv_algorithm = iv_algorithm
      iv_old_oid = iv_expected_oid ).
    mo_lock->release( ).
  ENDMETHOD.

ENDCLASS.
