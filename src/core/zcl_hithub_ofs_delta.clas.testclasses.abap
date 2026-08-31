CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS decodes_ofs_delta FOR TESTING RAISING cx_static_check.
    METHODS rejects_bad_delta FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD decodes_ofs_delta.
    DATA lv_base TYPE xstring.
    DATA lv_delta TYPE xstring.
    DATA lv_entry_header TYPE xstring.
    DATA lv_distance TYPE xstring.
    DATA lv_data TYPE xstring.
    DATA lv_result TYPE xstring.
    DATA lv_expected TYPE xstring.

    lv_base = cl_abap_codepage=>convert_to( source = 'abcdef' ).
    lv_delta = CONV xstring( '060990030358595A910303' ).
    lv_entry_header = CONV xstring( '68' ).
    lv_distance = CONV xstring( '01' ).
    CONCATENATE lv_entry_header lv_distance lv_delta INTO lv_data IN BYTE MODE.

    lv_result = zcl_hithub_ofs_delta=>decode(
      iv_data = lv_data iv_current_offset = 100 iv_base = lv_base ).
    lv_expected = cl_abap_codepage=>convert_to( source = 'abcXYZdef' ).

    ASSERT lv_result = lv_expected.
  ENDMETHOD.

  METHOD rejects_bad_delta.
    DATA lv_base TYPE xstring.
    DATA lv_result TYPE xstring.

    lv_base = cl_abap_codepage=>convert_to( source = 'abcdef' ).
    lv_result = zcl_hithub_delta_codec=>apply(
      iv_base = lv_base iv_delta = CONV xstring( '060A910303910303' ) ).
    ASSERT lv_result IS INITIAL.
    lv_result = zcl_hithub_delta_codec=>apply(
      iv_base = lv_base iv_delta = CONV xstring( '060381' ) ).
    ASSERT lv_result IS INITIAL.
    lv_result = zcl_hithub_delta_codec=>apply(
      iv_base = lv_base iv_delta = CONV xstring( '060390' ) ).
    ASSERT lv_result IS INITIAL.
    lv_result = zcl_hithub_delta_codec=>apply(
      iv_base            = lv_base
      iv_delta           = CONV xstring( '060990030358595A910303' )
      iv_max_result_size = 8 ).
    ASSERT lv_result IS INITIAL.
    lv_result = zcl_hithub_delta_codec=>apply(
      iv_base = lv_base
      iv_delta = CONV xstring( '060990030358595A910303' )
      iv_delta_depth = 2 iv_max_delta_depth = 1 ).
    ASSERT lv_result IS INITIAL.
  ENDMETHOD.

ENDCLASS.
