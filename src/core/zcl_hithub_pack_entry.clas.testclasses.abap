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

    ASSERT ls_entry-type = 'blob'.
    ASSERT ls_entry-size = 5.
    ASSERT ls_entry-data_offset = 1.
    ASSERT ls_entry-is_delta = abap_false.

    ls_entry = zcl_hithub_pack_entry=>parse( CONV xstring( '9101' ) ).
    ASSERT ls_entry-type = 'commit'.
    ASSERT ls_entry-size = 17.
    ASSERT ls_entry-data_offset = 2.
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
    ASSERT ls_entry-type = 'ref-delta'.
    ASSERT ls_entry-size = 0.
    ASSERT ls_entry-base_oid = lv_base_oid.
    ASSERT ls_entry-data_offset = 21.

    ls_entry = zcl_hithub_pack_entry=>parse( CONV xstring( '6010' ) ).
    ASSERT ls_entry-type = 'ofs-delta'.
    ASSERT ls_entry-size = 0.
    ASSERT ls_entry-base_distance = 16.
    ASSERT ls_entry-data_offset = 2.
  ENDMETHOD.

  METHOD builds_object_header.
    DATA lv_data TYPE xstring.

    lv_data = zcl_hithub_pack_entry=>build( iv_type = 'blob' iv_size = 5 ).
    ASSERT lv_data = CONV xstring( '35' ).
    lv_data = zcl_hithub_pack_entry=>build( iv_type = 'commit' iv_size = 17 ).
    ASSERT lv_data = CONV xstring( '9101' ).
    ASSERT zcl_hithub_pack_entry=>build( iv_type = 'blob' iv_size = -1 ) IS INITIAL.
    ASSERT zcl_hithub_pack_entry=>build( iv_type = 'unknown' iv_size = 1 ) IS INITIAL.
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
      ASSERT ls_entry-type = 'blob'.
      ASSERT ls_entry-size = lv_size.
      ASSERT ls_entry-data_offset = xstrlen( lv_data ).
    ENDDO.
  ENDMETHOD.

ENDCLASS.
