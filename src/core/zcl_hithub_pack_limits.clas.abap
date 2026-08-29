CLASS zcl_hithub_pack_limits DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        iv_max_pack_size TYPE int8 DEFAULT 524288000
        iv_max_objects   TYPE i DEFAULT 100000.

    METHODS is_allowed
      IMPORTING
        iv_pack_size      TYPE int8
        iv_objects        TYPE i
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_max_pack_size TYPE int8.
    DATA mv_max_objects TYPE i.

ENDCLASS.

CLASS zcl_hithub_pack_limits IMPLEMENTATION.

  METHOD constructor.
    mv_max_pack_size = iv_max_pack_size.
    mv_max_objects = iv_max_objects.
  ENDMETHOD.

  METHOD is_allowed.
    CLEAR rv_allowed.
    IF iv_pack_size < 0 OR iv_objects < 0.
      RETURN.
    ENDIF.
    IF iv_pack_size > mv_max_pack_size OR iv_objects > mv_max_objects.
      RETURN.
    ENDIF.
    rv_allowed = abap_true.
  ENDMETHOD.

ENDCLASS.
