CLASS zcl_hithub_object_writer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_store TYPE REF TO zif_hithub_object_store.

    METHODS write
      IMPORTING
        is_object TYPE zif_hithub_object_store=>ty_object
      RETURNING
        VALUE(rv_created) TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_store TYPE REF TO zif_hithub_object_store.

ENDCLASS.

CLASS zcl_hithub_object_writer IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
  ENDMETHOD.

  METHOD write.
    DATA lv_expected_oid TYPE string.

    CLEAR rv_created.
    IF mo_store IS INITIAL.
      RETURN.
    ENDIF.
    CASE is_object-type.
      WHEN 'blob' OR 'tree' OR 'commit' OR 'tag'.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    IF is_object-size <> xstrlen( is_object-payload ).
      RETURN.
    ENDIF.
    IF zcl_hithub_oid_validator=>is_valid(
        iv_algorithm = is_object-key-algorithm
        iv_oid = is_object-key-oid ) = abap_false.
      RETURN.
    ENDIF.
    lv_expected_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = is_object-key-algorithm
      iv_type = is_object-type
      iv_payload = is_object-payload ).
    IF lv_expected_oid <> is_object-key-oid.
      RETURN.
    ENDIF.
    IF mo_store->contains( is_object-key ) = abap_true.
      RETURN.
    ENDIF.
    rv_created = mo_store->write( is_object ).
  ENDMETHOD.

ENDCLASS.
