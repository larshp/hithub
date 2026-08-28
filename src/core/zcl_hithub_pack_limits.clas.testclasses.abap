CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS enforces_configured_limits FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD enforces_configured_limits.
    DATA(lo_limits) = NEW zcl_hithub_pack_limits(
      iv_max_pack_size = 100 iv_max_objects = 2 ).

    ASSERT lo_limits->is_allowed( iv_pack_size = 100 iv_objects = 2 ) = abap_true.
    ASSERT lo_limits->is_allowed( iv_pack_size = 101 iv_objects = 2 ) = abap_false.
    ASSERT lo_limits->is_allowed( iv_pack_size = 100 iv_objects = 3 ) = abap_false.
    ASSERT lo_limits->is_allowed( iv_pack_size = -1 iv_objects = 0 ) = abap_false.
  ENDMETHOD.

ENDCLASS.
