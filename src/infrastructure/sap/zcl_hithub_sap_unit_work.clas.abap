CLASS zcl_hithub_sap_unit_work DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_transaction.

  PRIVATE SECTION.
    DATA mv_active TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_sap_unit_work IMPLEMENTATION.

  METHOD zif_hithub_transaction~start.
    mv_active = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_transaction~commit.
    IF mv_active <> abap_true.
      RETURN.
    ENDIF.
    COMMIT WORK AND WAIT.
    CLEAR mv_active.
  ENDMETHOD.

  METHOD zif_hithub_transaction~rollback.
    IF mv_active <> abap_true.
      RETURN.
    ENDIF.
    ROLLBACK WORK.
    CLEAR mv_active.
  ENDMETHOD.

  METHOD zif_hithub_transaction~is_active.
    rv_active = mv_active.
  ENDMETHOD.

ENDCLASS.
