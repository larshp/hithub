CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS lists_prefixed_refs FOR TESTING RAISING cx_static_check.
    METHODS includes_symref_target FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD lists_prefixed_refs.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_prefixes TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
    DATA lv_rest TYPE xstring.

    ls_reference-repository_id = 'repo-v2'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    APPEND ls_reference TO lt_references.
    ls_reference-name = 'refs/tags/v1'.
    ls_reference-oid = '2222222222222222222222222222222222222222'.
    APPEND ls_reference TO lt_references.
    APPEND 'refs/heads/' TO lt_prefixes.
    lv_response = zcl_hithub_v2_ls_refs=>build(
      iv_repository_id = 'repo-v2'
      it_references = lt_references
      it_ref_prefixes = lt_prefixes ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = '1111111111111111111111111111111111111111 refs/heads/main' &&
        cl_abap_char_utilities=>newline ).
    lv_rest = lv_response+ls_packet-consumed_bytes.
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_rest ).
    ASSERT ls_packet-kind = 'flush'.
  ENDMETHOD.

  METHOD includes_symref_target.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_response TYPE xstring.
    DATA ls_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.

    ls_reference-repository_id = 'repo-v2'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-name = 'HEAD'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    ls_reference-symbolic_target = 'refs/heads/main'.
    APPEND ls_reference TO lt_references.
    lv_response = zcl_hithub_v2_ls_refs=>build(
      iv_repository_id = 'repo-v2'
      it_references = lt_references iv_symrefs = abap_true ).
    ls_packet = zcl_hithub_pkt_line_codec=>decode( lv_response ).
    ASSERT ls_packet-payload = cl_abap_codepage=>convert_to(
      source = '1111111111111111111111111111111111111111 HEAD' &&
        ' symref-target:refs/heads/main' && cl_abap_char_utilities=>newline ).
  ENDMETHOD.

ENDCLASS.
