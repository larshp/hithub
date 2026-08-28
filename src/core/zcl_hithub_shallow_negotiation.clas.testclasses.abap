CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS builds_depth_one_boundary FOR TESTING RAISING cx_static_check.
    METHODS builds_depth_two_boundary FOR TESTING RAISING cx_static_check.
    METHODS rejects_non_positive_depth FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD builds_depth_one_boundary.
    DATA lt_start TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lt_commits TYPE zcl_hithub_shallow_negotiation=>ty_commits.
    DATA ls_commit TYPE zcl_hithub_shallow_negotiation=>ty_commit.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_tip TYPE string.

    lv_tip = '1111111111111111111111111111111111111111'.
    APPEND lv_tip TO lt_start.
    ls_commit-oid = lv_tip.
    APPEND '2222222222222222222222222222222222222222' TO ls_commit-parents.
    APPEND ls_commit TO lt_commits.
    lv_response = zcl_hithub_shallow_negotiation=>build(
      it_start_oids = lt_start it_commits = lt_commits iv_depth = 1 ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = |shallow { lv_tip }| && cl_abap_char_utilities=>newline ).
  ENDMETHOD.

  METHOD builds_depth_two_boundary.
    DATA lt_start TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lt_commits TYPE zcl_hithub_shallow_negotiation=>ty_commits.
    DATA ls_commit TYPE zcl_hithub_shallow_negotiation=>ty_commit.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    APPEND '1111111111111111111111111111111111111111' TO lt_start.
    ls_commit-oid = '1111111111111111111111111111111111111111'.
    APPEND '2222222222222222222222222222222222222222' TO ls_commit-parents.
    APPEND ls_commit TO lt_commits.
    CLEAR ls_commit.
    ls_commit-oid = '2222222222222222222222222222222222222222'.
    APPEND '3333333333333333333333333333333333333333' TO ls_commit-parents.
    APPEND ls_commit TO lt_commits.
    lv_response = zcl_hithub_shallow_negotiation=>build(
      it_start_oids = lt_start it_commits = lt_commits iv_depth = 2 ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = 'shallow 2222222222222222222222222222222222222222' &&
        cl_abap_char_utilities=>newline ).
  ENDMETHOD.

  METHOD rejects_non_positive_depth.
    DATA lt_start TYPE zcl_hithub_upload_request=>ty_lines.

    APPEND '1111111111111111111111111111111111111111' TO lt_start.
    ASSERT zcl_hithub_shallow_negotiation=>build(
      it_start_oids = lt_start it_commits = VALUE #( ) iv_depth = 0 ) IS INITIAL.
  ENDMETHOD.

ENDCLASS.
