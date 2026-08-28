CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS preserves_copy_invariants FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD preserves_copy_invariants.
    DATA lv_base TYPE xstring.
    DATA lv_delta TYPE xstring.
    DATA lv_result TYPE xstring.

    DO 3 TIMES.
      CASE sy-index.
        WHEN 1.
          lv_base = CONV xstring( '61' ).
          lv_delta = CONV xstring( '01019001' ).
        WHEN 2.
          lv_base = CONV xstring( '6162' ).
          lv_delta = CONV xstring( '02029002' ).
        WHEN 3.
          lv_base = CONV xstring( '616263' ).
          lv_delta = CONV xstring( '03039003' ).
      ENDCASE.
      lv_result = zcl_hithub_delta_codec=>apply(
        iv_base = lv_base iv_delta = lv_delta ).
      ASSERT lv_result = lv_base.
    ENDDO.
  ENDMETHOD.

ENDCLASS.
