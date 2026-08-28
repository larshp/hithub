CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS parses_pack_header FOR TESTING RAISING cx_static_check.
    METHODS rejects_invalid_header FOR TESTING RAISING cx_static_check.
    METHODS builds_pack_header FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD parses_pack_header.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.

    ls_header = zcl_hithub_pack_header=>parse(
      CONV xstring( '5041434B0000000200000003' ) ).

    ASSERT ls_header-signature = 'PACK'.
    ASSERT ls_header-version = 2.
    ASSERT ls_header-object_count = 3.
  ENDMETHOD.

  METHOD rejects_invalid_header.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.

    ls_header = zcl_hithub_pack_header=>parse( CONV xstring( '5041434B' ) ).
    ASSERT ls_header-signature IS INITIAL.
    ls_header = zcl_hithub_pack_header=>parse(
      CONV xstring( '504143580000000200000003' ) ).
    ASSERT ls_header-signature IS INITIAL.
    ls_header = zcl_hithub_pack_header=>parse(
      CONV xstring( '5041434B0000000100000003' ) ).
    ASSERT ls_header-signature IS INITIAL.
  ENDMETHOD.

  METHOD builds_pack_header.
    DATA lv_data TYPE xstring.

    lv_data = zcl_hithub_pack_header=>build( 3 ).

    ASSERT lv_data = CONV xstring( '5041434B0000000200000003' ).
  ENDMETHOD.

ENDCLASS.
