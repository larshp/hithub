CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_object_header FOR TESTING RAISING cx_static_check.
    METHODS parses_delta_headers FOR TESTING RAISING cx_static_check.
    METHODS builds_object_header FOR TESTING RAISING cx_static_check.
    METHODS round_trips_size_varints FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_object_header.
    DATA ls_entry TYPE zcl_hithub_pack_entry=>ty_entry.

    ls_entry = zcl_hithub_pack_entry=>parse( CONV xstring( '35010203' ) ).

    cl_abap_unit_assert=>assert_equals( act = ls_entry-type exp = 'blob' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-size exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-data_offset exp = 1 ).
    cl_abap_unit_assert=>assert_false( act = ls_entry-is_delta ).

    ls_entry = zcl_hithub_pack_entry=>parse( CONV xstring( '9101' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-type exp = 'commit' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-size exp = 17 ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-data_offset exp = 2 ).
  ENDMETHOD.

  METHOD parses_delta_headers.
    DATA ls_entry TYPE zcl_hithub_pack_entry=>ty_entry.
    DATA lv_base_oid TYPE xstring.
    DATA lv_ref_prefix TYPE xstring.
    DATA lv_ref_data TYPE xstring.

    lv_base_oid = CONV xstring( '1111111111111111111111111111111111111111' ).
    lv_ref_prefix = CONV xstring( '70' ).
    CONCATENATE lv_ref_prefix lv_base_oid INTO lv_ref_data IN BYTE MODE.
    ls_entry = zcl_hithub_pack_entry=>parse( lv_ref_data ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-type exp = 'ref-delta' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-size exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_entry-base_oid
      exp = lv_base_oid ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-data_offset exp = 21 ).

    ls_entry = zcl_hithub_pack_entry=>parse( CONV xstring( '6010' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-type exp = 'ofs-delta' ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-size exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-base_distance exp = 16 ).
    cl_abap_unit_assert=>assert_equals( act = ls_entry-data_offset exp = 2 ).
  ENDMETHOD.

  METHOD builds_object_header.
    DATA lv_data TYPE xstring.

    lv_data = zcl_hithub_pack_entry=>build( iv_type = 'blob' iv_size = 5 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_data
      exp = CONV xstring( '35' ) ).
    lv_data = zcl_hithub_pack_entry=>build( iv_type = 'commit' iv_size = 17 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_data
      exp = CONV xstring( '9101' ) ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_hithub_pack_entry=>build( iv_type = 'blob' iv_size = -1 ) ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_hithub_pack_entry=>build( iv_type = 'unknown' iv_size = 1 ) ).
  ENDMETHOD.

  METHOD round_trips_size_varints.
    DATA lv_size TYPE int8.
    DATA lv_data TYPE xstring.
    DATA ls_entry TYPE zcl_hithub_pack_entry=>ty_entry.

    DO 7 TIMES.
      CASE sy-index.
        WHEN 1.
          lv_size = 0.
        WHEN 2.
          lv_size = 1.
        WHEN 3.
          lv_size = 15.
        WHEN 4.
          lv_size = 16.
        WHEN 5.
          lv_size = 127.
        WHEN 6.
          lv_size = 128.
        WHEN 7.
          lv_size = 4096.
      ENDCASE.
      lv_data = zcl_hithub_pack_entry=>build(
        iv_type = 'blob' iv_size = lv_size ).
      ls_entry = zcl_hithub_pack_entry=>parse( lv_data ).
      cl_abap_unit_assert=>assert_equals( act = ls_entry-type exp = 'blob' ).
      cl_abap_unit_assert=>assert_equals( act = ls_entry-size exp = lv_size ).
      cl_abap_unit_assert=>assert_equals(
        act = ls_entry-data_offset
        exp = xstrlen( lv_data ) ).
    ENDDO.
  ENDMETHOD.

ENDCLASS.
