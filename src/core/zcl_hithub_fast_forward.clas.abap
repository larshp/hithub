CLASS zcl_hithub_fast_forward DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS allows_update
      IMPORTING
        io_reachability   TYPE REF TO zcl_hithub_reachability
        is_old            TYPE zif_hithub_object_store=>ty_object_key
        is_new            TYPE zif_hithub_object_store=>ty_object_key
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_fast_forward IMPLEMENTATION.

  METHOD allows_update.
    DATA lt_keys TYPE zcl_hithub_reachability=>ty_keys.

    CLEAR rv_allowed.
    IF io_reachability IS INITIAL
        OR is_old-repository_id IS INITIAL
        OR is_old-repository_id <> is_new-repository_id
        OR is_old-algorithm <> is_new-algorithm.
      RETURN.
    ENDIF.
    IF is_old-oid = '0000000000000000000000000000000000000000'.
      rv_allowed = abap_true.
      RETURN.
    ENDIF.
    IF is_new-oid = '0000000000000000000000000000000000000000'.
      RETURN.
    ENDIF.
    IF zcl_hithub_oid_validator=>is_valid(
        iv_algorithm = is_old-algorithm iv_oid = is_old-oid ) = abap_false
        OR zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = is_new-algorithm iv_oid = is_new-oid ) = abap_false.
      RETURN.
    ENDIF.
    lt_keys = io_reachability->walk( is_new ).
    READ TABLE lt_keys TRANSPORTING NO FIELDS
      WITH KEY repository_id = is_old-repository_id
        algorithm = is_old-algorithm oid = is_old-oid.
    rv_allowed = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

ENDCLASS.
