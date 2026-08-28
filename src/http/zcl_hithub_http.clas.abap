CLASS zcl_hithub_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.
ENDCLASS.

CLASS zcl_hithub_http IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_path) = server->request->get_header_field( '~path' ).
    DATA(lv_service) = server->request->get_form_field( 'service' ).
    DATA(lv_git_protocol) = server->request->get_header_field( 'Git-Protocol' ).

    IF lv_path = '/health' OR lv_path IS INITIAL.
      server->response->set_status(
        code   = 200
        reason = 'OK' ).
      server->response->set_content_type( 'application/json' ).
      server->response->set_cdata(
        '{"status":"ok","build":"dev","runtime":"abap",' &&
        '"database":"not-configured"}' ).
    ELSEIF lv_path CP '*/git-upload-pack'.
      DATA lv_upload_repository_name TYPE string.
      DATA lv_upload_body TYPE xstring.
      DATA ls_upload_repository TYPE zif_hithub_metadata_store=>ty_repository.
      DATA lt_upload_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
      DATA lt_upload_references TYPE zif_hithub_metadata_store=>ty_references.
      DATA lv_upload_request TYPE xstring.
      DATA lv_upload_command TYPE string.
      DATA ls_upload_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
      DATA(lo_upload_metadata) = NEW zcl_hithub_local_meta_store( ).

      FIND REGEX '^/(.*)\.git/git-upload-pack$' IN lv_path
        SUBMATCHES lv_upload_repository_name.
      lt_upload_repositories =
        lo_upload_metadata->zif_hithub_metadata_store~list_repositories( ).
      LOOP AT lt_upload_repositories INTO ls_upload_repository.
        IF ls_upload_repository-name = lv_upload_repository_name.
          EXIT.
        ENDIF.
        CLEAR ls_upload_repository.
      ENDLOOP.
      IF ls_upload_repository-id IS NOT INITIAL.
        lt_upload_references =
          lo_upload_metadata->zif_hithub_metadata_store~list_references(
            ls_upload_repository-id ).
      ENDIF.
      IF ls_upload_repository-id IS NOT INITIAL AND lv_git_protocol CS 'version=2'.
        lv_upload_request = server->request->get_data( ).
        ls_upload_packet = zcl_hithub_pkt_line_codec=>decode(
          lv_upload_request ).
        IF ls_upload_packet-valid = abap_true AND ls_upload_packet-kind = 'data'.
          lv_upload_command = cl_abap_codepage=>convert_from(
            source = ls_upload_packet-payload ).
        ENDIF.
      ENDIF.
      IF ls_upload_repository-id IS NOT INITIAL
          AND lv_git_protocol CS 'version=2'
          AND lv_upload_command CP 'command=ls-refs*'.
        lv_upload_body = zcl_hithub_v2_ls_refs=>build(
          iv_repository_id = ls_upload_repository-id
          it_references = lt_upload_references ).
        server->response->set_status(
          code = 200 reason = 'OK' ).
        server->response->set_content_type(
          'application/x-git-upload-pack-result' ).
        server->response->set_data( lv_upload_body ).
      ELSEIF ls_upload_repository-id IS NOT INITIAL
          AND lv_git_protocol CS 'version=2'
          AND lv_upload_command CP 'command=fetch*'.
        DATA(ls_fetch_request) = zcl_hithub_v2_fetch=>parse( lv_upload_request ).
        IF ls_fetch_request-valid = abap_true.
          DATA(lo_upload_store) = NEW zcl_hithub_local_object_store( ).
          DATA(lo_upload_reader) = NEW zcl_hithub_object_reader( lo_upload_store ).
          DATA(lo_reachability) = NEW zcl_hithub_reachability( lo_upload_reader ).
          DATA lt_upload_objects TYPE zcl_hithub_pack_codec=>ty_objects.
          DATA lt_upload_keys TYPE zcl_hithub_reachability=>ty_keys.
          DATA ls_upload_key TYPE zif_hithub_object_store=>ty_object_key.
          DATA ls_upload_object TYPE zif_hithub_object_store=>ty_object.
          DATA lv_upload_oid TYPE string.
          DATA(lo_upload_compression) = NEW zcl_hithub_abap_compression( ).
          DATA(lo_upload_codec) = NEW zcl_hithub_pack_codec( lo_upload_compression ).

          LOOP AT ls_fetch_request-wants INTO lv_upload_oid.
            CLEAR ls_upload_key.
            ls_upload_key-repository_id = ls_upload_repository-id.
            ls_upload_key-algorithm = 'sha1'.
            ls_upload_key-oid = lv_upload_oid.
            lt_upload_keys = lo_reachability->walk( ls_upload_key ).
            LOOP AT lt_upload_keys INTO ls_upload_key.
              READ TABLE lt_upload_objects TRANSPORTING NO FIELDS
                WITH KEY key-repository_id = ls_upload_key-repository_id
                  key-algorithm = ls_upload_key-algorithm key-oid = ls_upload_key-oid.
              IF sy-subrc = 0.
                CONTINUE.
              ENDIF.
              ls_upload_object = lo_upload_reader->read( ls_upload_key ).
              IF ls_upload_object-key-oid IS NOT INITIAL.
                APPEND ls_upload_object TO lt_upload_objects.
              ENDIF.
            ENDLOOP.
          ENDLOOP.
          lv_upload_body = lo_upload_codec->repack( lt_upload_objects ).
          lv_upload_body = zcl_hithub_v2_fetch=>build_response( lv_upload_body ).
        ENDIF.
        IF lv_upload_body IS NOT INITIAL.
          server->response->set_status(
            code = 200 reason = 'OK' ).
          server->response->set_content_type(
            'application/x-git-upload-pack-result' ).
          server->response->set_data( lv_upload_body ).
        ELSE.
          server->response->set_status(
            code = 400 reason = 'Bad Request' ).
          server->response->set_content_type( 'application/json' ).
          server->response->set_cdata( '{"status":"invalid-fetch"}' ).
        ENDIF.
      ELSEIF ls_upload_repository-id IS NOT INITIAL AND lt_upload_references IS INITIAL.
        lv_upload_body = zcl_hithub_pkt_line_codec=>encode(
          cl_abap_codepage=>convert_to(
            source = 'NAK' && cl_abap_char_utilities=>newline ) ).
        DATA(lv_upload_flush) = zcl_hithub_pkt_line_codec=>flush( ).
        CONCATENATE lv_upload_body lv_upload_flush
          INTO lv_upload_body IN BYTE MODE.
        server->response->set_status(
          code = 200 reason = 'OK' ).
        server->response->set_content_type(
          'application/x-git-upload-pack-result' ).
        server->response->set_data( lv_upload_body ).
      ELSE.
        server->response->set_status(
          code = 501 reason = 'Not Implemented' ).
        server->response->set_content_type( 'application/json' ).
        server->response->set_cdata( '{"status":"upload-pack-not-implemented"}' ).
      ENDIF.
    ELSEIF lv_service = 'git-upload-pack'.
      DATA lv_repository_name TYPE string.
      DATA lv_head_ref TYPE string.
      DATA lv_body TYPE xstring.
      DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
      DATA ls_head TYPE zif_hithub_metadata_store=>ty_reference.
      DATA lt_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
      DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
      DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).

      FIND REGEX '^/(.*)\.git/info/refs$' IN lv_path
        SUBMATCHES lv_repository_name.
      IF sy-subrc = 0 AND lv_repository_name IS NOT INITIAL.
        lt_repositories = lo_metadata->zif_hithub_metadata_store~list_repositories( ).
        LOOP AT lt_repositories INTO ls_repository.
          IF ls_repository-name = lv_repository_name.
            EXIT.
          ENDIF.
          CLEAR ls_repository.
        ENDLOOP.
      ENDIF.
      IF ls_repository-id IS NOT INITIAL AND lv_git_protocol CS 'version=2'.
        lv_body = zcl_hithub_protocol_v2=>advertise( ).
      ELSEIF ls_repository-id IS NOT INITIAL.
        lv_head_ref = ls_repository-default_branch.
        IF lv_head_ref IS INITIAL.
          lv_head_ref = 'refs/heads/main'.
        ELSEIF lv_head_ref NP 'refs/*'.
          lv_head_ref = |refs/heads/{ lv_head_ref }|.
        ENDIF.
        ls_head = lo_metadata->zif_hithub_metadata_store~read_reference(
          iv_repository_id = ls_repository-id iv_name = lv_head_ref ).
        lt_references = lo_metadata->zif_hithub_metadata_store~list_references(
          ls_repository-id ).
        lv_body = zcl_hithub_upload_discovery=>build(
          iv_service = lv_service
          iv_head_oid = ls_head-oid
          iv_head_ref = lv_head_ref
          iv_repository_id = ls_repository-id
          it_references = lt_references ).
      ENDIF.
      IF lv_body IS NOT INITIAL.
        server->response->set_status(
          code = 200 reason = 'OK' ).
        server->response->set_header_field(
          name = 'Cache-Control' value = 'no-cache' ).
        server->response->set_content_type(
          'application/x-git-upload-pack-advertisement' ).
        server->response->set_data( lv_body ).
      ELSE.
        server->response->set_status(
          code = 404 reason = 'Not Found' ).
        server->response->set_content_type( 'application/json' ).
        server->response->set_cdata( '{"status":"not-found"}' ).
      ENDIF.
    ELSE.
      server->response->set_status(
        code   = 404
        reason = 'Not Found' ).
      server->response->set_content_type( 'application/json' ).
      server->response->set_cdata( '{"status":"not-found"}' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
