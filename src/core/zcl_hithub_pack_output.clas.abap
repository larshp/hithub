CLASS zcl_hithub_pack_output DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_pack_output.

  PRIVATE SECTION.
    DATA mv_data TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_pack_output IMPLEMENTATION.

  METHOD zif_hithub_pack_output~write.
    IF iv_data IS INITIAL.
      RETURN.
    ENDIF.
    CONCATENATE mv_data iv_data INTO mv_data IN BYTE MODE.
  ENDMETHOD.

  METHOD zif_hithub_pack_output~get_data.
    rv_data = mv_data.
  ENDMETHOD.

ENDCLASS.
