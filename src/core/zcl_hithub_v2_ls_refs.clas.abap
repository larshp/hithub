CLASS zcl_hithub_v2_ls_refs DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS build
      IMPORTING
        iv_repository_id   TYPE string OPTIONAL
        iv_algorithm       TYPE string DEFAULT 'sha1'
        it_references      TYPE zif_hithub_metadata_store=>ty_references
        it_ref_prefixes    TYPE zcl_hithub_upload_request=>ty_lines OPTIONAL
        iv_symrefs         TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_v2_ls_refs IMPLEMENTATION.

  METHOD build.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_prefix TYPE string.
    DATA lv_pattern TYPE string.
    DATA lv_line TYPE string.
    DATA lv_text TYPE xstring.
    DATA lv_packet TYPE xstring.
    DATA lv_matches_prefix TYPE abap_bool.

    CLEAR rv_response.
    lt_references = it_references.
    IF iv_repository_id IS NOT INITIAL.
      lt_references = zcl_hithub_ref_visibility=>filter(
        iv_repository_id = iv_repository_id
        iv_algorithm     = iv_algorithm
        it_references    = it_references ).
    ENDIF.

    LOOP AT lt_references INTO ls_reference.
      IF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = iv_algorithm iv_oid = ls_reference-oid ) = abap_false.
        CONTINUE.
      ENDIF.
      IF it_ref_prefixes IS NOT INITIAL.
        CLEAR lv_matches_prefix.
        LOOP AT it_ref_prefixes INTO lv_prefix.
          IF lv_prefix IS INITIAL.
            lv_matches_prefix = abap_true.
            EXIT.
          ENDIF.
          lv_pattern = lv_prefix && '*'.
          IF ls_reference-name CP lv_pattern.
            lv_matches_prefix = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lv_matches_prefix = abap_false.
          CONTINUE.
        ENDIF.
      ENDIF.

      lv_line = |{ ls_reference-oid } { ls_reference-name }|.
      IF iv_symrefs = abap_true AND ls_reference-symbolic_target IS NOT INITIAL.
        lv_line = lv_line && | symref-target:{ ls_reference-symbolic_target }|.
      ENDIF.
      lv_line = lv_line && cl_abap_char_utilities=>newline.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ENDLOOP.

    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
