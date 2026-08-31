CLASS zcl_hithub_receive_target DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS is_valid_target
      IMPORTING
        io_store        TYPE REF TO zif_hithub_object_store
        is_key          TYPE zif_hithub_object_store=>ty_object_key
        iv_ref_name     TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_receive_target IMPLEMENTATION.

  METHOD is_valid_target.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    CLEAR rv_valid.
    IF zcl_hithub_ref_validator=>is_valid( iv_ref_name ) = abap_false.
      RETURN.
    ENDIF.
    IF is_key-oid = '0000000000000000000000000000000000000000'.
      rv_valid = abap_true.
      RETURN.
    ENDIF.
    IF io_store IS INITIAL
        OR zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = is_key-algorithm iv_oid = is_key-oid ) = abap_false.
      RETURN.
    ENDIF.
    ls_object = io_store->read( is_key ).
    IF ls_object-key-oid IS INITIAL.
      RETURN.
    ENDIF.
    IF iv_ref_name CP 'refs/heads/*'.
      rv_valid = xsdbool( ls_object-type = 'commit' ).
    ELSEIF iv_ref_name CP 'refs/tags/*'.
      rv_valid = xsdbool( ls_object-type = 'commit'
        OR ls_object-type = 'tag' ).
    ELSE.
      rv_valid = xsdbool( ls_object-type = 'blob'
        OR ls_object-type = 'tree'
        OR ls_object-type = 'commit'
        OR ls_object-type = 'tag' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
