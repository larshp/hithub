CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS emits_nul_terminated_header FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD emits_nul_terminated_header.
    DATA lv_header TYPE xstring.

    lv_header = zcl_hithub_object_header=>generate(
      iv_type = 'blob' iv_size = 4 ).

    ASSERT lv_header = CONV xstring( '626C6F62203400' ).
  ENDMETHOD.

ENDCLASS.
