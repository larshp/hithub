CLASS zcl_hithub_local_unit_work DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_transaction.

  PRIVATE SECTION.
    DATA mv_active TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_local_unit_work IMPLEMENTATION.

  METHOD zif_hithub_transaction~start.
    IF mv_active = abap_true.
      RETURN.
    ENDIF.
    DATA(lo_sql) = NEW cl_sql_statement( ).
    lo_sql->execute_update( statement = 'BEGIN TRANSACTION' ).
    mv_active = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_transaction~commit.
    IF mv_active <> abap_true.
      RETURN.
    ENDIF.
    DATA(lo_sql) = NEW cl_sql_statement( ).
    lo_sql->execute_update( statement = 'COMMIT' ).
    CLEAR mv_active.
  ENDMETHOD.

  METHOD zif_hithub_transaction~rollback.
    IF mv_active <> abap_true.
      RETURN.
    ENDIF.
    DATA(lo_sql) = NEW cl_sql_statement( ).
    lo_sql->execute_update( statement = 'ROLLBACK' ).
    CLEAR mv_active.
  ENDMETHOD.

  METHOD zif_hithub_transaction~is_active.
    rv_active = mv_active.
  ENDMETHOD.

ENDCLASS.
