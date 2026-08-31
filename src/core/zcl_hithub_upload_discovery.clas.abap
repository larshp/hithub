CLASS zcl_hithub_upload_discovery DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS build
      IMPORTING
        iv_service       TYPE string
        iv_head_oid      TYPE string
        iv_head_ref      TYPE string
        iv_repository_id TYPE string OPTIONAL
        it_references    TYPE zif_hithub_metadata_store=>ty_references
        it_capabilities  TYPE zcl_hithub_git_capabilities=>ty_capabilities OPTIONAL
      RETURNING
        VALUE(rv_body)   TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_upload_discovery IMPLEMENTATION.

  METHOD build.
    DATA lv_line TYPE string.
    DATA lv_packet TYPE xstring.
    DATA lv_text TYPE xstring.
    DATA lv_nul TYPE xstring.
    DATA lv_capabilities TYPE string.
    DATA lv_head_prefix TYPE xstring.
    DATA lv_capability_bytes TYPE xstring.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA lt_capabilities TYPE zcl_hithub_git_capabilities=>ty_capabilities.

    CLEAR rv_body.
    IF ( iv_service <> 'git-upload-pack' AND
        iv_service <> 'git-receive-pack' )
        OR zcl_hithub_ref_validator=>is_valid( iv_head_ref ) = abap_false
        OR ( iv_head_oid IS NOT INITIAL AND
          zcl_hithub_oid_validator=>is_valid(
            iv_algorithm = 'sha1' iv_oid = iv_head_oid ) = abap_false ).
      RETURN.
    ENDIF.

    lv_line = |# service={ iv_service }| && cl_abap_char_utilities=>newline.
    lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_body lv_packet INTO rv_body IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_body lv_packet INTO rv_body IN BYTE MODE.

    IF iv_head_oid IS INITIAL.
      lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
      CONCATENATE rv_body lv_packet INTO rv_body IN BYTE MODE.
      RETURN.
    ENDIF.

    lv_head_prefix = cl_abap_codepage=>convert_to(
      source = |{ iv_head_oid } HEAD| ).
    lv_nul = CONV xstring( '00' ).
    IF it_capabilities IS INITIAL.
      IF iv_service = 'git-receive-pack'.
        lt_capabilities = zcl_hithub_git_capabilities=>receive_advertised( ).
      ELSE.
        lt_capabilities = zcl_hithub_git_capabilities=>advertised( iv_head_ref ).
      ENDIF.
    ELSE.
      lt_capabilities = it_capabilities.
    ENDIF.
    lv_capabilities = zcl_hithub_git_capabilities=>render( lt_capabilities ).
    lv_capability_bytes = cl_abap_codepage=>convert_to(
      source = lv_capabilities && cl_abap_char_utilities=>newline ).
    CONCATENATE lv_head_prefix lv_nul lv_capability_bytes
      INTO lv_text IN BYTE MODE.
    lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
    CONCATENATE rv_body lv_packet INTO rv_body IN BYTE MODE.

    lt_references = it_references.
    IF iv_repository_id IS NOT INITIAL.
      lt_references = zcl_hithub_ref_visibility=>filter(
        iv_repository_id = iv_repository_id
        iv_algorithm     = 'sha1'
        it_references    = it_references ).
    ENDIF.
    LOOP AT lt_references INTO ls_reference.
      IF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha1' iv_oid = ls_reference-oid ) = abap_false
          OR zcl_hithub_ref_validator=>is_valid( ls_reference-name ) = abap_false.
        CONTINUE.
      ENDIF.
      lv_line = |{ ls_reference-oid } { ls_reference-name }| &&
        cl_abap_char_utilities=>newline.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_body lv_packet INTO rv_body IN BYTE MODE.
    ENDLOOP.

    lv_packet = zcl_hithub_pkt_line_codec=>flush( ).
    CONCATENATE rv_body lv_packet INTO rv_body IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
