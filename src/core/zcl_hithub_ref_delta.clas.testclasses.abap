CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS decodes_ref_delta FOR TESTING RAISING cx_static_check.
    METHODS rejects_wrong_entry FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD decodes_ref_delta.
    DATA lv_base TYPE xstring.
    DATA lv_base_oid TYPE xstring.
    DATA lv_header TYPE xstring.
    DATA lv_delta TYPE xstring.
    DATA lv_data TYPE xstring.
    DATA lv_result TYPE xstring.
    DATA lv_expected TYPE xstring.

    lv_base = cl_abap_codepage=>convert_to( source = 'abcdef' ).
    lv_base_oid = CONV xstring( '1111111111111111111111111111111111111111' ).
    lv_header = CONV xstring( '7B' ).
    lv_delta = CONV xstring( '060990030358595A910303' ).
    CONCATENATE lv_header lv_base_oid lv_delta INTO lv_data IN BYTE MODE.

    lv_result = zcl_hithub_ref_delta=>decode(
      iv_data = lv_data iv_base = lv_base ).
    lv_expected = cl_abap_codepage=>convert_to( source = 'abcXYZdef' ).

    ASSERT lv_result = lv_expected.
  ENDMETHOD.

  METHOD rejects_wrong_entry.
    DATA lv_result TYPE xstring.

    lv_result = zcl_hithub_ref_delta=>decode(
      iv_data = CONV xstring( '6801' )
      iv_base = CONV xstring( '616263' ) ).
    ASSERT lv_result IS INITIAL.
  ENDMETHOD.

ENDCLASS.
