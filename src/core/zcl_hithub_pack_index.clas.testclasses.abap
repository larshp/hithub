CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS indexes_unique_objects FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD indexes_unique_objects.
    DATA(lo_index) = NEW zcl_hithub_pack_index( ).
    DATA lt_entries TYPE zcl_hithub_pack_index=>ty_entries.

    cl_abap_unit_assert=>assert_true(
      act = lo_index->add( iv_oid = 'aaa' iv_offset = 12 ) ).
    cl_abap_unit_assert=>assert_true(
      act = lo_index->add( iv_oid = 'bbb' iv_offset = 24 ) ).
    cl_abap_unit_assert=>assert_false(
      act = lo_index->add( iv_oid = 'aaa' iv_offset = 48 ) ).
    cl_abap_unit_assert=>assert_false(
      act = lo_index->add( iv_oid = '' iv_offset = 60 ) ).
    cl_abap_unit_assert=>assert_false(
      act = lo_index->add( iv_oid = 'ccc' iv_offset = -1 ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_index->find( 'aaa' )
      exp = 12 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_index->find( 'missing' )
      exp = 0 ).

    lt_entries = lo_index->all( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_entries ) exp = 2 ).
  ENDMETHOD.

ENDCLASS.
