CLASS zcl_hithub_ref_update_policy DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS old_oid_matches
      IMPORTING
        io_metadata       TYPE REF TO zif_hithub_metadata_store
        iv_repository_id TYPE string
        iv_ref_name      TYPE string
        iv_algorithm     TYPE string
        iv_old_oid       TYPE string
      RETURNING
        VALUE(rv_matches) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_ref_update_policy IMPLEMENTATION.

  METHOD old_oid_matches.
    CONSTANTS lc_zero_oid TYPE string VALUE
      '0000000000000000000000000000000000000000'.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    CLEAR rv_matches.
    IF io_metadata IS INITIAL
        OR zcl_hithub_ref_validator=>is_valid( iv_ref_name ) = abap_false.
      RETURN.
    ENDIF.
    IF iv_old_oid <> lc_zero_oid
        AND zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = iv_algorithm iv_oid = iv_old_oid ) = abap_false.
      RETURN.
    ENDIF.

    ls_reference = io_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = iv_ref_name ).
    IF iv_old_oid = lc_zero_oid.
      rv_matches = xsdbool( ls_reference-oid IS INITIAL ).
      RETURN.
    ENDIF.

    rv_matches = xsdbool( ls_reference-algorithm = iv_algorithm
      AND ls_reference-oid = iv_old_oid ).
  ENDMETHOD.

ENDCLASS.
