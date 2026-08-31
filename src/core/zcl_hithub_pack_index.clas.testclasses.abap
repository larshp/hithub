CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS indexes_unique_objects FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD indexes_unique_objects.
    DATA(lo_index) = NEW zcl_hithub_pack_index( ).
    DATA lt_entries TYPE zcl_hithub_pack_index=>ty_entries.

    ASSERT lo_index->add( iv_oid = 'aaa' iv_offset = 12 ) = abap_true.
    ASSERT lo_index->add( iv_oid = 'bbb' iv_offset = 24 ) = abap_true.
    ASSERT lo_index->add( iv_oid = 'aaa' iv_offset = 48 ) = abap_false.
    ASSERT lo_index->add( iv_oid = '' iv_offset = 60 ) = abap_false.
    ASSERT lo_index->add( iv_oid = 'ccc' iv_offset = -1 ) = abap_false.
    ASSERT lo_index->find( 'aaa' ) = 12.
    ASSERT lo_index->find( 'missing' ) = 0.

    lt_entries = lo_index->all( ).
    ASSERT lines( lt_entries ) = 2.
  ENDMETHOD.

ENDCLASS.
