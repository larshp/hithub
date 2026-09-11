CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS calculates_git_sha1 FOR TESTING RAISING cx_static_check.
    METHODS calculates_golden_ids FOR TESTING RAISING cx_static_check.
    METHODS packs_and_unpacks_oids FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD calculates_git_sha1.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.

    lv_payload = cl_abap_codepage=>convert_to( 'hello' ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0' ).
  ENDMETHOD.

  METHOD calculates_golden_ids.
    DATA lv_payload TYPE xstring.
    DATA lv_oid TYPE string.
    DATA lv_byte TYPE xstring.

    CLEAR lv_payload.
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' ).

    lv_payload = cl_abap_codepage=>convert_to( source = |hello{ cl_abap_char_utilities=>newline }| ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = 'ce013625030ba8dba906f756967f9e9ca394464a' ).

    lv_payload = CONV xstring( '0001027F80FF' ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = 'ac0deae0c6de979e3136dcc6bdb1d07c58d37107' ).

    lv_payload = cl_abap_codepage=>convert_to(
      source = |Hällo 🌍{ cl_abap_char_utilities=>newline }| ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = '83d5089f5ae0d203e46984bbddffe11606382cf0' ).

    CLEAR lv_payload.
    lv_byte = CONV xstring( '61' ).
    DO 4096 TIMES.
      CONCATENATE lv_payload lv_byte INTO lv_payload IN BYTE MODE.
    ENDDO.
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'blob' iv_payload = lv_payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_oid
      exp = '9d235ed07cd19811a6ceb342de82f190e49c9f68' ).
  ENDMETHOD.

  METHOD packs_and_unpacks_oids.
    " calculate( ) returns lower case hex, while character to byte
    " conversion reads upper case hex digits only and stops at the first
    " other character. to_bytes( ) and from_bytes( ) bridge that gap for
    " tree entries and pack entries.
    DATA lv_lower TYPE string.
    DATA lv_upper TYPE string.

    lv_lower = 'abcdef0123456789abcdef0123456789abcdef01'.
    lv_upper = 'ABCDEF0123456789ABCDEF0123456789ABCDEF01'.

    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( zcl_hithub_object_id=>to_bytes( lv_lower ) )
      exp = 20
      msg = 'a lower case oid does not pack into 20 bytes' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_object_id=>to_bytes( lv_lower )
      exp = zcl_hithub_object_id=>to_bytes( lv_upper )
      msg = 'case decides which bytes an oid packs into' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_object_id=>from_bytes(
        zcl_hithub_object_id=>to_bytes( lv_lower ) )
      exp = lv_lower
      msg = 'an oid does not survive to_bytes and from_bytes' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hithub_object_id=>from_bytes(
        zcl_hithub_object_id=>to_bytes( lv_upper ) )
      exp = lv_lower
      msg = 'from_bytes does not normalise to lower case' ).

    " Two ids that differ only in a hex letter must not pack alike.
    cl_abap_unit_assert=>assert_differs(
      act = zcl_hithub_object_id=>to_bytes(
        'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' )
      exp = zcl_hithub_object_id=>to_bytes(
        'e69de29bb2d1d6434b8b29ae775ad8c2e48c539f' )
      msg = 'different oids pack into the same bytes' ).

    cl_abap_unit_assert=>assert_initial(
      act = zcl_hithub_object_id=>to_bytes( '' ) ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_hithub_object_id=>from_bytes( CONV xstring( '' ) ) ).
  ENDMETHOD.

ENDCLASS.
