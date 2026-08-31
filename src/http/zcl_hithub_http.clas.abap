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
    DATA(ls_route) = zcl_hithub_http_router=>resolve(
      iv_path = lv_path iv_service = lv_service ).

    IF ls_route-kind = 'health'.
      server->response->set_status(
        code   = 200
        reason = 'OK' ).
      server->response->set_content_type( 'application/json' ).
      server->response->set_cdata(
        '{"status":"ok","build":"dev","runtime":"abap",' &&
        '"database":"not-configured"}' ).
    ELSEIF ls_route-kind = 'git-upload-pack'
        OR ls_route-kind = 'git-receive-pack'.
      DATA lv_upload_repository_name TYPE string.
      DATA lv_upload_body TYPE xstring.
      DATA lv_receive_request TYPE abap_bool.
      DATA ls_upload_repository TYPE zif_hithub_metadata_store=>ty_repository.
      DATA lt_upload_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
      DATA lt_upload_references TYPE zif_hithub_metadata_store=>ty_references.
      DATA ls_upload_head TYPE zif_hithub_metadata_store=>ty_reference.
      DATA lv_upload_head_ref TYPE string.
      DATA lv_upload_request TYPE xstring.
      DATA lv_upload_command TYPE string.
      DATA ls_upload_packet TYPE zcl_hithub_pkt_line_codec=>ty_packet.
      DATA ls_legacy_request TYPE zcl_hithub_upload_request=>ty_request.
      DATA lt_legacy_common TYPE zcl_hithub_upload_request=>ty_lines.
      DATA lt_legacy_objects TYPE zcl_hithub_pack_codec=>ty_objects.
      DATA lt_legacy_keys TYPE zcl_hithub_reachability=>ty_keys.
      DATA ls_legacy_key TYPE zif_hithub_object_store=>ty_object_key.
      DATA ls_legacy_object TYPE zif_hithub_object_store=>ty_object.
      DATA lv_legacy_oid TYPE string.
      DATA lv_legacy_negotiation TYPE xstring.
      DATA lv_legacy_sideband TYPE xstring.
      DATA lv_legacy_sideband_requested TYPE abap_bool.
      DATA ls_receive_request TYPE zcl_hithub_receive_request=>ty_request.
      DATA ls_receive_command TYPE zcl_hithub_receive_request=>ty_command.
      DATA ls_receive_result TYPE zcl_hithub_receive_status=>ty_result.
      DATA lt_receive_results TYPE zcl_hithub_receive_status=>ty_results.
      DATA lv_receive_response TYPE xstring.
      DATA lv_receive_sideband TYPE xstring.
      DATA lv_receive_ok TYPE abap_bool.
      DATA lv_receive_sideband_requested TYPE abap_bool.
      DATA ls_receive_current TYPE zif_hithub_metadata_store=>ty_reference.
      DATA(lo_upload_metadata) = zcl_hithub_persistence=>metadata_store( ).

      IF ls_route-kind = 'git-receive-pack'.
        lv_receive_request = abap_true.
        lv_service = 'git-receive-pack'.
      ENDIF.

      lv_upload_repository_name = ls_route-repository_name.
      lt_upload_repositories =
        lo_upload_metadata->list_repositories( ).
      LOOP AT lt_upload_repositories INTO ls_upload_repository.
        IF ls_upload_repository-name = lv_upload_repository_name.
          EXIT.
        ENDIF.
        CLEAR ls_upload_repository.
      ENDLOOP.
      IF ls_upload_repository-id IS NOT INITIAL.
        lt_upload_references =
          lo_upload_metadata->list_references(
            ls_upload_repository-id ).
      ENDIF.
      IF lv_receive_request = abap_true.
        ls_receive_request = zcl_hithub_receive_request=>parse(
          server->request->get_data( ) ).
        IF ls_upload_repository-id IS NOT INITIAL
            AND ls_receive_request-valid = abap_true.
          lv_receive_ok = abap_true.
          IF lines( ls_receive_request-commands ) > 1.
            DATA(lo_batch_store) = zcl_hithub_persistence=>object_store( ).
            DATA(lo_batch_reader) = NEW zcl_hithub_object_reader(
              lo_batch_store ).
            DATA(lo_batch_base) = NEW zcl_hithub_pack_base_resolver(
              lo_batch_reader ).
            DATA(lo_batch_compression) =
              NEW zcl_hithub_abap_compression( ).
            DATA(lo_batch_codec) = NEW zcl_hithub_pack_codec(
              io_compression   = lo_batch_compression
              io_base_resolver = lo_batch_base ).
            DATA(lo_batch_transaction) = zcl_hithub_persistence=>transaction( ).
            DATA(lo_batch) = NEW zcl_hithub_receive_batch(
              io_store = lo_batch_store io_metadata = lo_upload_metadata
              io_codec = lo_batch_codec io_transaction = lo_batch_transaction ).
            lo_batch->apply(
              EXPORTING
                iv_repository_id = ls_upload_repository-id
                iv_pack          = ls_receive_request-pack
                it_commands      = ls_receive_request-commands
              IMPORTING
                et_results       = lt_receive_results
                rv_success       = lv_receive_ok ).
          ELSE.
          LOOP AT ls_receive_request-commands INTO ls_receive_command.
            CLEAR ls_receive_result.
            ls_receive_result-ref_name = ls_receive_command-ref_name.
            ls_receive_current =
              lo_upload_metadata->read_reference(
                iv_repository_id = ls_upload_repository-id
                iv_name          = ls_receive_command-ref_name ).
            IF zcl_hithub_ref_update_policy=>old_oid_matches(
                io_metadata      = lo_upload_metadata
                iv_repository_id = ls_upload_repository-id
                iv_ref_name      = ls_receive_command-ref_name
                iv_algorithm     = 'sha1'
                iv_old_oid       = ls_receive_command-old_oid ) = abap_false.
              ls_receive_result-reason = 'stale info'.
              lv_receive_ok = abap_false.
            ELSEIF ls_receive_command-new_oid =
                '0000000000000000000000000000000000000000'.
              IF ls_receive_current-oid IS INITIAL.
                ls_receive_result-reason = 'reference not found'.
                lv_receive_ok = abap_false.
              ELSE.
                DATA(lo_delete_transaction) = zcl_hithub_persistence=>transaction( ).
                lo_delete_transaction->start( ).
                lo_upload_metadata->delete_reference(
                  iv_repository_id    = ls_upload_repository-id
                  iv_name             = ls_receive_command-ref_name
                  iv_expected_version = ls_receive_current-version ).
                lo_delete_transaction->commit( ).
                ls_receive_result-ok = abap_true.
              ENDIF.
            ELSE.
              DATA(lo_receive_store) = zcl_hithub_persistence=>object_store( ).
              DATA ls_receive_key TYPE zif_hithub_object_store=>ty_object_key.
              DATA ls_receive_reference TYPE zif_hithub_metadata_store=>ty_reference.
              DATA ls_receive_header TYPE zcl_hithub_pack_header=>ty_header.
              DATA lv_receive_version TYPE int8.
              ls_receive_key-repository_id = ls_upload_repository-id.
              ls_receive_key-algorithm = 'sha1'.
              ls_receive_key-oid = ls_receive_command-new_oid.
              ls_receive_header = zcl_hithub_pack_header=>parse(
                ls_receive_request-pack ).
              IF ( xstrlen( ls_receive_request-pack ) = 0
                  OR ( ls_receive_header-signature = 'PACK'
                    AND ls_receive_header-object_count = 0 ) )
                  AND zcl_hithub_receive_target=>is_valid_target(
                    io_store = lo_receive_store is_key = ls_receive_key
                    iv_ref_name = ls_receive_command-ref_name ) = abap_true.
                DATA(lo_existing_transaction) = zcl_hithub_persistence=>transaction( ).
                lo_existing_transaction->start( ).
                ls_receive_reference-repository_id = ls_upload_repository-id.
                ls_receive_reference-name = ls_receive_command-ref_name.
                ls_receive_reference-algorithm = 'sha1'.
                ls_receive_reference-oid = ls_receive_command-new_oid.
                lv_receive_version =
                  lo_upload_metadata->save_reference(
                    is_reference        = ls_receive_reference
                    iv_expected_version = ls_receive_current-version ).
                IF lv_receive_version IS INITIAL.
                  lo_existing_transaction->rollback( ).
                  ls_receive_result-reason = 'ref update failed'.
                  lv_receive_ok = abap_false.
                ELSE.
                  lo_existing_transaction->commit( ).
                  ls_receive_result-ok = abap_true.
                ENDIF.
              ELSE.
                DATA(lo_receive_reader) = NEW zcl_hithub_object_reader(
                  lo_receive_store ).
                DATA(lo_receive_base) = NEW zcl_hithub_pack_base_resolver(
                  lo_receive_reader ).
                DATA(lo_receive_compression) =
                  NEW zcl_hithub_abap_compression( ).
                DATA(lo_receive_codec) = NEW zcl_hithub_pack_codec(
                  io_compression   = lo_receive_compression
                  io_base_resolver = lo_receive_base ).
                DATA(lo_receive_transaction) = zcl_hithub_persistence=>transaction( ).
                DATA(lo_receive_receiver) = NEW zcl_hithub_pack_receiver(
                  io_codec = lo_receive_codec io_store = lo_receive_store
                  io_metadata = lo_upload_metadata
                  io_transaction = lo_receive_transaction ).
                IF lo_receive_receiver->receive(
                    iv_pack             = ls_receive_request-pack
                    iv_repository_id    = ls_upload_repository-id
                    iv_ref_name         = ls_receive_command-ref_name
                    iv_target_oid       = ls_receive_command-new_oid
                    iv_expected_version = ls_receive_current-version ) =
                    abap_true.
                  ls_receive_result-ok = abap_true.
                ELSE.
                  ls_receive_result-reason = 'unpack or update failed'.
                  lv_receive_ok = abap_false.
                ENDIF.
              ENDIF.
            ENDIF.
            APPEND ls_receive_result TO lt_receive_results.
          ENDLOOP.
          ENDIF.
          lv_receive_response = zcl_hithub_receive_status=>build(
            iv_unpack_ok = lv_receive_ok
            it_results   = lt_receive_results ).
          READ TABLE ls_receive_request-capabilities
            WITH KEY table_line = 'side-band-64k' TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lv_receive_sideband_requested = abap_true.
          ELSE.
            READ TABLE ls_receive_request-capabilities
              WITH KEY table_line = 'side-band' TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              lv_receive_sideband_requested = abap_true.
            ENDIF.
          ENDIF.
          IF lv_receive_sideband_requested = abap_true.
            lv_receive_sideband = zcl_hithub_receive_sideband=>build(
              lv_receive_response ).
            lv_receive_response = lv_receive_sideband.
          ENDIF.
        ENDIF.
        IF lv_receive_response IS NOT INITIAL.
          server->response->set_status(
            code = 200 reason = 'OK' ).
          server->response->set_content_type(
            'application/x-git-receive-pack-result' ).
          server->response->set_data( lv_receive_response ).
        ELSE.
          server->response->set_status(
            code = 400 reason = 'Bad Request' ).
          server->response->set_content_type( 'application/json' ).
          server->response->set_cdata( '{"status":"invalid-push"}' ).
        ENDIF.
      ELSEIF ls_upload_repository-id IS NOT INITIAL
          AND lv_git_protocol CS 'version=2'
          AND lv_service = 'git-upload-pack'.
        lv_upload_request = server->request->get_data( ).
        ls_upload_packet = zcl_hithub_pkt_line_codec=>decode(
          lv_upload_request ).
        IF ls_upload_packet-valid = abap_true AND ls_upload_packet-kind = 'data'.
          lv_upload_command = cl_abap_codepage=>convert_from(
            source = ls_upload_packet-payload ).
        ENDIF.
      ENDIF.
      IF lv_receive_request = abap_false
          AND ls_upload_repository-id IS NOT INITIAL
          AND lv_git_protocol CS 'version=2'
          AND lv_upload_command CP 'command=ls-refs*'.
        lv_upload_head_ref = ls_upload_repository-default_branch.
        IF lv_upload_head_ref IS INITIAL.
          lv_upload_head_ref = 'refs/heads/main'.
        ELSEIF lv_upload_head_ref NP 'refs/*'.
          lv_upload_head_ref = |refs/heads/{ lv_upload_head_ref }|.
        ENDIF.
        ls_upload_head = lo_upload_metadata->read_reference(
          iv_repository_id = ls_upload_repository-id
          iv_name          = lv_upload_head_ref ).
        IF ls_upload_head-oid IS NOT INITIAL.
          ls_upload_head-name = 'HEAD'.
          ls_upload_head-symbolic_target = lv_upload_head_ref.
          APPEND ls_upload_head TO lt_upload_references.
        ENDIF.
        lv_upload_body = zcl_hithub_v2_ls_refs=>build(
          iv_repository_id = ls_upload_repository-id
          it_references    = lt_upload_references
          iv_symrefs       = abap_true ).
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
          DATA(lo_upload_store) = zcl_hithub_persistence=>object_store( ).
          DATA(lo_upload_reader) = NEW zcl_hithub_object_reader( lo_upload_store ).
          DATA(lo_reachability) = NEW zcl_hithub_reachability( lo_upload_reader ).
          DATA lt_upload_objects TYPE zcl_hithub_pack_codec=>ty_objects.
          DATA lt_upload_keys TYPE zcl_hithub_reachability=>ty_keys.
      DATA ls_upload_key TYPE zif_hithub_object_store=>ty_object_key.
      DATA ls_upload_object TYPE zif_hithub_object_store=>ty_object.
      DATA lt_upload_common_haves TYPE zcl_hithub_v2_fetch=>ty_lines.
      DATA lv_upload_ack TYPE xstring.
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
          LOOP AT ls_fetch_request-haves INTO lv_upload_oid.
            CLEAR ls_upload_key.
            ls_upload_key-repository_id = ls_upload_repository-id.
            ls_upload_key-algorithm = 'sha1'.
            ls_upload_key-oid = lv_upload_oid.
            IF lo_upload_store->contains(
                ls_upload_key ) = abap_true.
              APPEND lv_upload_oid TO lt_upload_common_haves.
            ENDIF.
          ENDLOOP.
          lv_upload_body = lo_upload_codec->repack( lt_upload_objects ).
          lv_upload_body = zcl_hithub_v2_fetch=>build_response( lv_upload_body ).
          IF ls_fetch_request-haves IS NOT INITIAL
              AND ls_fetch_request-saw_done = abap_false.
            lv_upload_ack = zcl_hithub_v2_fetch=>build_acknowledgments(
              lt_upload_common_haves ).
            CONCATENATE lv_upload_ack lv_upload_body INTO lv_upload_body
              IN BYTE MODE.
          ENDIF.
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
      ELSEIF lv_receive_request = abap_false
          AND ls_upload_repository-id IS NOT INITIAL
          AND lt_upload_references IS NOT INITIAL.
        ls_legacy_request = zcl_hithub_upload_request=>parse(
          server->request->get_data( ) ).
        IF ls_legacy_request-valid = abap_true.
          DATA(lo_legacy_store) = zcl_hithub_persistence=>object_store( ).
          DATA(lo_legacy_reader) = NEW zcl_hithub_object_reader( lo_legacy_store ).
          DATA(lo_legacy_reachability) = NEW zcl_hithub_reachability( lo_legacy_reader ).
          DATA(lo_legacy_compression) = NEW zcl_hithub_abap_compression( ).
          DATA(lo_legacy_codec) = NEW zcl_hithub_pack_codec( lo_legacy_compression ).

          LOOP AT ls_legacy_request-wants INTO lv_legacy_oid.
            CLEAR ls_legacy_key.
            ls_legacy_key-repository_id = ls_upload_repository-id.
            ls_legacy_key-algorithm = 'sha1'.
            ls_legacy_key-oid = lv_legacy_oid.
            lt_legacy_keys = lo_legacy_reachability->walk( ls_legacy_key ).
            LOOP AT lt_legacy_keys INTO ls_legacy_key.
              READ TABLE lt_legacy_objects TRANSPORTING NO FIELDS
                WITH KEY key-repository_id = ls_legacy_key-repository_id
                  key-algorithm = ls_legacy_key-algorithm
                  key-oid = ls_legacy_key-oid.
              IF sy-subrc = 0.
                CONTINUE.
              ENDIF.
              ls_legacy_object = lo_legacy_reader->read( ls_legacy_key ).
              IF ls_legacy_object-key-oid IS NOT INITIAL.
                APPEND ls_legacy_object TO lt_legacy_objects.
              ENDIF.
            ENDLOOP.
          ENDLOOP.

          LOOP AT ls_legacy_request-haves INTO lv_legacy_oid.
            CLEAR ls_legacy_key.
            ls_legacy_key-repository_id = ls_upload_repository-id.
            ls_legacy_key-algorithm = 'sha1'.
            ls_legacy_key-oid = lv_legacy_oid.
            IF lo_legacy_store->contains(
                is_key = ls_legacy_key ) = abap_true.
              APPEND lv_legacy_oid TO lt_legacy_common.
            ENDIF.
          ENDLOOP.

          lv_legacy_negotiation = zcl_hithub_upload_negotiation=>build(
            is_request = ls_legacy_request
            it_common  = lt_legacy_common ).
          lv_upload_body = lo_legacy_codec->repack( lt_legacy_objects ).
          READ TABLE ls_legacy_request-capabilities
            WITH KEY table_line = 'side-band-64k'
            TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lv_legacy_sideband_requested = abap_true.
          ELSE.
            READ TABLE ls_legacy_request-capabilities
              WITH KEY table_line = 'side-band'
              TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              lv_legacy_sideband_requested = abap_true.
            ENDIF.
          ENDIF.
          IF lv_legacy_sideband_requested = abap_true.
            lv_legacy_sideband = zcl_hithub_sideband_output=>build(
              lv_upload_body ).
          ELSE.
            lv_legacy_sideband = lv_upload_body.
          ENDIF.
          CONCATENATE lv_legacy_negotiation lv_legacy_sideband
            INTO lv_upload_body IN BYTE MODE.
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
      ELSEIF lv_receive_request = abap_false
          AND ls_upload_repository-id IS NOT INITIAL
          AND lt_upload_references IS INITIAL.
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
      ELSEIF lv_receive_request = abap_true.
      ELSE.
        server->response->set_status(
          code = 501 reason = 'Not Implemented' ).
        server->response->set_content_type( 'application/json' ).
        server->response->set_cdata( '{"status":"upload-pack-not-implemented"}' ).
      ENDIF.
    ELSEIF ls_route-kind = 'git-discovery'.
      DATA lv_repository_name TYPE string.
      DATA lv_head_ref TYPE string.
      DATA lv_body TYPE xstring.
      DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
      DATA ls_head TYPE zif_hithub_metadata_store=>ty_reference.
      DATA lt_repositories TYPE zif_hithub_metadata_store=>ty_repositories.
      DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
      DATA(lo_metadata) = zcl_hithub_persistence=>metadata_store( ).

      lv_repository_name = ls_route-repository_name.
      IF lv_repository_name IS NOT INITIAL.
        lt_repositories = lo_metadata->list_repositories( ).
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
        ls_head = lo_metadata->read_reference(
          iv_repository_id = ls_repository-id iv_name = lv_head_ref ).
        lt_references = lo_metadata->list_references(
          ls_repository-id ).
        lv_body = zcl_hithub_upload_discovery=>build(
          iv_service       = lv_service
          iv_head_oid      = ls_head-oid
          iv_head_ref      = lv_head_ref
          iv_repository_id = ls_repository-id
          it_references    = lt_references ).
      ENDIF.
      IF lv_body IS NOT INITIAL.
        server->response->set_status(
          code = 200 reason = 'OK' ).
        server->response->set_header_field(
          name = 'Cache-Control' value = 'no-cache' ).
        server->response->set_content_type(
          |application/x-{ lv_service }-advertisement| ).
        server->response->set_data( lv_body ).
      ELSE.
        server->response->set_status(
          code = 404 reason = 'Not Found' ).
        server->response->set_content_type( 'application/json' ).
        server->response->set_cdata( '{"status":"not-found"}' ).
      ENDIF.
    ELSEIF ls_route-kind = 'rest'.
      DATA(lv_rest_method) = server->request->get_method( ).
      DATA(lo_rest_query) = NEW zcl_hithub_repository_query(
        zcl_hithub_persistence=>metadata_store( ) ).
      DATA(lo_audit_sink) = zcl_hithub_persistence=>event_sink( ).
      IF zcl_hithub_pr_discussion_api=>matches( lv_path ) = abap_true
          OR zcl_hithub_issue_meta_api=>matches( lv_path ) = abap_true
          OR ( lv_rest_method = 'PUT'
            AND zcl_hithub_contents_api=>matches( lv_path ) = abap_true ).
        DATA ls_delegated TYPE zcl_hithub_rest_response=>ty_response.
        DATA(lo_delegated_context) = zcl_hithub_rest_context=>for_local(
          iv_method = lv_rest_method iv_path = lv_path
          iv_body = server->request->get_data( )
          iv_correlation_id = server->request->get_header_field(
            'X-Request-ID' ) ).
        IF zcl_hithub_pr_discussion_api=>matches( lv_path ) = abap_true.
          ls_delegated = zcl_hithub_pr_discussion_api=>handle(
            io_context = lo_delegated_context io_sink = lo_audit_sink ).
        ELSEIF zcl_hithub_issue_meta_api=>matches( lv_path ) = abap_true.
          ls_delegated = zcl_hithub_issue_meta_api=>handle(
            io_context = lo_delegated_context io_sink = lo_audit_sink ).
        ELSE.
          ls_delegated = zcl_hithub_contents_api=>handle(
            io_context = lo_delegated_context io_sink = lo_audit_sink ).
        ENDIF.
        server->response->set_status(
          code = ls_delegated-status reason = ls_delegated-reason ).
        IF ls_delegated-location IS NOT INITIAL.
          server->response->set_header_field(
            name = 'Location' value = ls_delegated-location ).
        ENDIF.
        server->response->set_content_type( ls_delegated-content_type ).
        server->response->set_data( ls_delegated-body ).
      ELSEIF lv_rest_method = 'PUT' AND lv_path CS '/pulls/'
          AND lv_path CS '/merge'.
        DATA lv_merge_repo_name TYPE string.
        DATA lv_merge_pr_id TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/pulls/([^/]+)/merge$'
          IN lv_path SUBMATCHES lv_merge_repo_name lv_merge_pr_id.
        DATA(ls_merge_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Merge route was not found.'
          iv_instance = lv_path ).
        IF sy-subrc <> 0 OR lv_merge_repo_name IS INITIAL
            OR lv_merge_pr_id IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_merge_problem-content_type ).
          server->response->set_data( ls_merge_problem-body ).
        ELSE.
          DATA(ls_merge_repository) = lo_rest_query->find( lv_merge_repo_name ).
          IF ls_merge_repository-id IS INITIAL.
            ls_merge_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_merge_problem-content_type ).
            server->response->set_data( ls_merge_problem-body ).
          ELSE.
            DATA(ls_merge_document) = zcl_hithub_json=>parse_data(
              server->request->get_data( ) ).
            DATA lv_merge_valid TYPE abap_bool.
            DATA lv_merge_head TYPE string.
            DATA lv_merge_message TYPE string.
            DATA lv_merge_author TYPE string.
            DATA lv_merge_committer TYPE string.
            DATA lv_merge_clean TYPE abap_bool.
            DATA lv_merge_head_seen TYPE abap_bool.
            DATA lv_merge_clean_seen TYPE abap_bool.
            DATA ls_merge_member TYPE zcl_hithub_json=>ty_member.
            lv_merge_valid = ls_merge_document-valid.
            lv_merge_author = zcl_hithub_commit_signature=>build( 'HitHub' ).
            lv_merge_committer = lv_merge_author.
            lv_merge_message = |Merge pull request { lv_merge_pr_id }|.
            LOOP AT ls_merge_document-members INTO ls_merge_member.
              CASE ls_merge_member-name.
                WHEN 'expected_head_oid'.
                  IF ls_merge_member-kind <> 'string'.
                    lv_merge_valid = abap_false.
                  ELSE.
                    lv_merge_head = ls_merge_member-value.
                    lv_merge_head_seen = abap_true.
                  ENDIF.
                WHEN 'clean'.
                  IF ls_merge_member-kind <> 'boolean'.
                    lv_merge_valid = abap_false.
                  ELSE.
                    lv_merge_clean = xsdbool( ls_merge_member-value = 'true' ).
                    lv_merge_clean_seen = abap_true.
                  ENDIF.
                WHEN 'message'.
                  IF ls_merge_member-kind <> 'string'.
                    lv_merge_valid = abap_false.
                  ELSE.
                    lv_merge_message = ls_merge_member-value.
                  ENDIF.
                WHEN 'author'.
                  IF ls_merge_member-kind <> 'string'.
                    lv_merge_valid = abap_false.
                  ELSE.
                    lv_merge_author = ls_merge_member-value.
                  ENDIF.
                WHEN 'committer'.
                  IF ls_merge_member-kind <> 'string'.
                    lv_merge_valid = abap_false.
                  ELSE.
                    lv_merge_committer = ls_merge_member-value.
                  ENDIF.
                WHEN OTHERS.
                  lv_merge_valid = abap_false.
              ENDCASE.
            ENDLOOP.
            IF lv_merge_head_seen = abap_false OR lv_merge_clean_seen = abap_false.
              lv_merge_valid = abap_false.
            ENDIF.
            IF lv_merge_valid = abap_false.
              ls_merge_problem = zcl_hithub_problem_response=>build(
                iv_status   = 400
                iv_detail   = 'Merge body must contain expected_head_oid and clean.'
                iv_instance = lv_path ).
              server->response->set_status( code = 400 reason = 'Bad Request' ).
              server->response->set_content_type(
                ls_merge_problem-content_type ).
              server->response->set_data( ls_merge_problem-body ).
            ELSE.
              DATA(lo_merge_store) = zcl_hithub_persistence=>object_store( ).
              DATA(lo_merge_metadata) = zcl_hithub_persistence=>metadata_store( ).
              DATA(lo_merge_transaction) = zcl_hithub_persistence=>transaction( ).
              DATA(lo_merge_service) = NEW zcl_hithub_merge_service(
                io_store = lo_merge_store io_metadata = lo_merge_metadata
                io_transaction = lo_merge_transaction
                io_lock = zcl_hithub_persistence=>repository_lock( )
                io_event_sink = zcl_hithub_persistence=>event_sink( ) ).
              DATA(ls_merge_result) = lo_merge_service->execute(
                iv_repository_id = ls_merge_repository-id
                iv_pull_request_id = lv_merge_pr_id
                iv_expected_head_oid = lv_merge_head
                iv_author = lv_merge_author iv_committer = lv_merge_committer
                iv_message = lv_merge_message iv_owner = 'local-merge'
                iv_clean = lv_merge_clean ).
              IF ls_merge_result-success = abap_false.
                DATA lv_merge_status TYPE i.
                IF ls_merge_result-reason CS 'stale'
                    OR ls_merge_result-reason CS 'references'.
                  lv_merge_status = 412.
                ELSEIF ls_merge_result-reason = 'pull request was not found'.
                  lv_merge_status = 404.
                ELSE.
                  lv_merge_status = 409.
                ENDIF.
                ls_merge_problem = zcl_hithub_problem_response=>build(
                  iv_status = lv_merge_status iv_detail = ls_merge_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_merge_status reason = 'Merge Failed' ).
                server->response->set_content_type(
                  ls_merge_problem-content_type ).
                server->response->set_data( ls_merge_problem-body ).
              ELSE.
                DATA lt_merge_response_members TYPE zcl_hithub_json=>ty_members.
                APPEND VALUE #( name = 'merge_id' kind = 'string'
                  value = ls_merge_result-merge_id ) TO lt_merge_response_members.
                APPEND VALUE #( name = 'commit_oid' kind = 'string'
                  value = ls_merge_result-commit_oid ) TO lt_merge_response_members.
                server->response->set_status( code = 200 reason = 'OK' ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_json=>serialize_data( lt_merge_response_members ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/pulls'.
        DATA lv_pr_get_repo_name TYPE string.
        DATA lv_pr_get_id TYPE string.
        DATA lv_pr_get_collection TYPE abap_bool.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/pulls$' IN lv_path
          SUBMATCHES lv_pr_get_repo_name.
        IF sy-subrc = 0.
          lv_pr_get_collection = abap_true.
        ELSE.
          FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/pulls/([^/]+)$'
            IN lv_path SUBMATCHES lv_pr_get_repo_name lv_pr_get_id.
        ENDIF.
        IF lv_pr_get_repo_name IS INITIAL.
          DATA(ls_pr_get_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Pull-request route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_pr_get_problem-content_type ).
          server->response->set_data( ls_pr_get_problem-body ).
        ELSE.
          DATA(ls_pr_get_repository) = lo_rest_query->find(
            lv_pr_get_repo_name ).
          IF ls_pr_get_repository-id IS INITIAL.
            ls_pr_get_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_pr_get_problem-content_type ).
            server->response->set_data( ls_pr_get_problem-body ).
          ELSEIF lv_pr_get_collection = abap_true.
            DATA(lt_pr_get_requests) = zcl_hithub_pull_requests=>list(
              ls_pr_get_repository-id ).
            server->response->set_status( code = 200 reason = 'OK' ).
            server->response->set_content_type( 'application/json' ).
            server->response->set_data(
              zcl_hithub_pr_repr=>list( lt_pr_get_requests ) ).
          ELSE.
            DATA(ls_pr_get_request) = zcl_hithub_pull_requests=>find(
              iv_repository_id = ls_pr_get_repository-id
              iv_id            = lv_pr_get_id ).
            IF ls_pr_get_request-id IS INITIAL.
              ls_pr_get_problem = zcl_hithub_problem_response=>build(
                iv_status = 404 iv_detail = 'Pull request was not found.'
                iv_instance = lv_path ).
              server->response->set_status( code = 404 reason = 'Not Found' ).
              server->response->set_content_type(
                ls_pr_get_problem-content_type ).
              server->response->set_data( ls_pr_get_problem-body ).
            ELSE.
              server->response->set_status( code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_pr_repr=>one( ls_pr_get_request ) ).
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/audit'.
        DATA lv_audit_repo_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/audit$' IN lv_path
          SUBMATCHES lv_audit_repo_name.
        DATA(ls_audit_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Audit route was not found.'
          iv_instance = lv_path ).
        IF sy-subrc <> 0 OR lv_audit_repo_name IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_audit_problem-content_type ).
          server->response->set_data( ls_audit_problem-body ).
        ELSE.
          DATA(ls_audit_repository) = lo_rest_query->find(
            lv_audit_repo_name ).
          IF ls_audit_repository-id IS INITIAL.
            ls_audit_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_audit_problem-content_type ).
            server->response->set_data( ls_audit_problem-body ).
          ELSE.
            DATA(lt_audit_entries) = zcl_hithub_timeline=>list_repository(
              ls_audit_repository-id ).
            server->response->set_status( code = 200 reason = 'OK' ).
            server->response->set_content_type( 'application/json' ).
            server->response->set_data(
              zcl_hithub_timeline_repr=>list( lt_audit_entries ) ).
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/activity'.
        DATA lv_activity_repo_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/activity$' IN lv_path
          SUBMATCHES lv_activity_repo_name.
        DATA(ls_activity_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Activity route was not found.'
          iv_instance = lv_path ).
        IF sy-subrc <> 0 OR lv_activity_repo_name IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_activity_problem-content_type ).
          server->response->set_data( ls_activity_problem-body ).
        ELSE.
          DATA(ls_activity_repository) = lo_rest_query->find(
            lv_activity_repo_name ).
          IF ls_activity_repository-id IS INITIAL.
            ls_activity_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_activity_problem-content_type ).
            server->response->set_data( ls_activity_problem-body ).
          ELSE.
            DATA(lt_activity_entries) = zcl_hithub_timeline=>list_repository(
              ls_activity_repository-id ).
            server->response->set_status( code = 200 reason = 'OK' ).
            server->response->set_content_type( 'application/json' ).
            server->response->set_data(
              zcl_hithub_timeline_repr=>list( lt_activity_entries ) ).
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/issues'.
        DATA lv_issue_get_repo_name TYPE string.
        DATA lv_issue_get_id TYPE string.
        DATA lv_issue_get_collection TYPE abap_bool.
        DATA lv_issue_get_comments TYPE abap_bool.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/issues/([^/]+)/comments$'
          IN lv_path SUBMATCHES lv_issue_get_repo_name lv_issue_get_id.
        IF sy-subrc = 0.
          lv_issue_get_comments = abap_true.
        ELSE.
          FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/issues$' IN lv_path
            SUBMATCHES lv_issue_get_repo_name.
          IF sy-subrc = 0.
            lv_issue_get_collection = abap_true.
          ELSE.
            FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/issues/([^/]+)$'
              IN lv_path SUBMATCHES lv_issue_get_repo_name lv_issue_get_id.
          ENDIF.
        ENDIF.
        DATA(ls_issue_get_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Issue route was not found.'
          iv_instance = lv_path ).
        IF lv_issue_get_repo_name IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_issue_get_problem-content_type ).
          server->response->set_data( ls_issue_get_problem-body ).
        ELSE.
          DATA(ls_issue_get_repository) = lo_rest_query->find(
            lv_issue_get_repo_name ).
          IF ls_issue_get_repository-id IS INITIAL.
            ls_issue_get_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_issue_get_problem-content_type ).
            server->response->set_data( ls_issue_get_problem-body ).
          ELSEIF lv_issue_get_collection = abap_true.
            DATA(lt_issue_get_issues) = zcl_hithub_issues=>list(
              ls_issue_get_repository-id ).
            server->response->set_status( code = 200 reason = 'OK' ).
            server->response->set_content_type( 'application/json' ).
            server->response->set_data(
              zcl_hithub_issue_repr=>list( lt_issue_get_issues ) ).
          ELSEIF lv_issue_get_comments = abap_true.
            DATA(lt_issue_get_comments) = zcl_hithub_issue_comments=>list(
              iv_repository_id = ls_issue_get_repository-id
              iv_issue_id      = lv_issue_get_id ).
            DATA lv_issue_get_comments_json TYPE string.
            DATA ls_issue_get_comment TYPE zcl_hithub_issue_comments=>ty_comment.
            DATA lt_issue_get_comment_members TYPE zcl_hithub_json=>ty_members.
            lv_issue_get_comments_json = '['.
            LOOP AT lt_issue_get_comments INTO ls_issue_get_comment.
              CLEAR lt_issue_get_comment_members.
              APPEND VALUE #( name = 'id' kind = 'string'
                value = ls_issue_get_comment-comment_id )
                TO lt_issue_get_comment_members.
              APPEND VALUE #( name = 'actor' kind = 'string'
                value = ls_issue_get_comment-actor )
                TO lt_issue_get_comment_members.
              APPEND VALUE #( name = 'body' kind = 'string'
                value = ls_issue_get_comment-body )
                TO lt_issue_get_comment_members.
              APPEND VALUE #( name = 'created_at' kind = 'string'
                value = ls_issue_get_comment-created_at )
                TO lt_issue_get_comment_members.
              IF lv_issue_get_comments_json <> '['.
                lv_issue_get_comments_json = lv_issue_get_comments_json && ','.
              ENDIF.
              lv_issue_get_comments_json = lv_issue_get_comments_json &&
                zcl_hithub_json=>serialize( lt_issue_get_comment_members ).
            ENDLOOP.
            lv_issue_get_comments_json = lv_issue_get_comments_json && ']'.
            server->response->set_status( code = 200 reason = 'OK' ).
            server->response->set_content_type( 'application/json' ).
            server->response->set_data( cl_abap_codepage=>convert_to(
              lv_issue_get_comments_json ) ).
          ELSE.
            DATA(ls_issue_get_issue) = zcl_hithub_issues=>read(
              iv_repository_id = ls_issue_get_repository-id
              iv_id            = lv_issue_get_id ).
            IF ls_issue_get_issue-id IS INITIAL.
              ls_issue_get_problem = zcl_hithub_problem_response=>build(
                iv_status = 404 iv_detail = 'Issue was not found.'
                iv_instance = lv_path ).
              server->response->set_status( code = 404 reason = 'Not Found' ).
              server->response->set_content_type(
                ls_issue_get_problem-content_type ).
              server->response->set_data( ls_issue_get_problem-body ).
            ELSE.
              server->response->set_status( code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_issue_repr=>one( ls_issue_get_issue ) ).
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_path = '/api/repos' AND lv_rest_method = 'GET'.
        DATA(lt_rest_repositories) = lo_rest_query->list( ).
        server->response->set_status(
          code = 200 reason = 'OK' ).
        server->response->set_content_type( 'application/json' ).
        server->response->set_data(
          zcl_hithub_repo_representation=>list( lt_rest_repositories ) ).
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/branches'.
        DATA lv_branch_get_repo_name TYPE string.
        DATA lv_branch_get_name TYPE string.
        DATA lv_branch_get_collection TYPE abap_bool.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/branches$' IN lv_path
          SUBMATCHES lv_branch_get_repo_name.
        IF sy-subrc = 0.
          lv_branch_get_collection = abap_true.
        ELSE.
          FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/branches/(.+)$'
            IN lv_path SUBMATCHES lv_branch_get_repo_name lv_branch_get_name.
        ENDIF.
        IF lv_branch_get_repo_name IS INITIAL.
          DATA(ls_branch_get_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Branch route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_branch_get_problem-content_type ).
          server->response->set_data( ls_branch_get_problem-body ).
        ELSE.
          DATA(ls_branch_get_repository) = lo_rest_query->find(
            lv_branch_get_repo_name ).
          IF ls_branch_get_repository-id IS INITIAL.
            ls_branch_get_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_branch_get_problem-content_type ).
            server->response->set_data( ls_branch_get_problem-body ).
          ELSE.
            DATA(lo_branch_get_service) = NEW zcl_hithub_branch_service(
              io_metadata    = zcl_hithub_persistence=>metadata_store( )
              io_transaction = zcl_hithub_persistence=>transaction( ) ).
            IF lv_branch_get_collection = abap_true.
              DATA(lt_branch_get_references) = lo_branch_get_service->list(
                ls_branch_get_repository-id ).
              server->response->set_status(
                code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_branch_repr=>list( lt_branch_get_references ) ).
            ELSE.
              DATA(ls_branch_get_reference) = lo_branch_get_service->find(
                iv_repository_id = ls_branch_get_repository-id
                iv_name          = lv_branch_get_name ).
              IF ls_branch_get_reference-name IS INITIAL.
                ls_branch_get_problem = zcl_hithub_problem_response=>build(
                  iv_status   = 404
                  iv_detail   = 'Branch was not found.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 404 reason = 'Not Found' ).
                server->response->set_content_type(
                  ls_branch_get_problem-content_type ).
                server->response->set_data( ls_branch_get_problem-body ).
              ELSE.
                server->response->set_status(
                  code = 200 reason = 'OK' ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_branch_repr=>one( ls_branch_get_reference ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/tags'.
        DATA lv_tag_get_repo_name TYPE string.
        DATA lv_tag_get_name TYPE string.
        DATA lv_tag_get_collection TYPE abap_bool.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/tags$' IN lv_path
          SUBMATCHES lv_tag_get_repo_name.
        IF sy-subrc = 0.
          lv_tag_get_collection = abap_true.
        ELSE.
          FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/tags/(.+)$'
            IN lv_path SUBMATCHES lv_tag_get_repo_name lv_tag_get_name.
        ENDIF.
        IF lv_tag_get_repo_name IS INITIAL.
          DATA(ls_tag_get_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Tag route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_tag_get_problem-content_type ).
          server->response->set_data( ls_tag_get_problem-body ).
        ELSE.
          DATA(ls_tag_get_repository) = lo_rest_query->find(
            lv_tag_get_repo_name ).
          IF ls_tag_get_repository-id IS INITIAL.
            ls_tag_get_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_tag_get_problem-content_type ).
            server->response->set_data( ls_tag_get_problem-body ).
          ELSE.
            DATA(lo_tag_get_service) = NEW zcl_hithub_tag_service(
              io_metadata    = zcl_hithub_persistence=>metadata_store( )
              io_transaction = zcl_hithub_persistence=>transaction( ) ).
            IF lv_tag_get_collection = abap_true.
              DATA(lt_tag_get_references) = lo_tag_get_service->list(
                ls_tag_get_repository-id ).
              server->response->set_status( code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_branch_repr=>list( lt_tag_get_references ) ).
            ELSE.
              DATA(ls_tag_get_reference) = lo_tag_get_service->find(
                iv_repository_id = ls_tag_get_repository-id
                iv_name          = lv_tag_get_name ).
              IF ls_tag_get_reference-name IS INITIAL.
                ls_tag_get_problem = zcl_hithub_problem_response=>build(
                  iv_status = 404 iv_detail = 'Tag was not found.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 404 reason = 'Not Found' ).
                server->response->set_content_type(
                  ls_tag_get_problem-content_type ).
                server->response->set_data( ls_tag_get_problem-body ).
              ELSE.
                server->response->set_status( code = 200 reason = 'OK' ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_branch_repr=>one( ls_tag_get_reference ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET'
          AND ( lv_path CP '/api/repos/*/commits'
            OR lv_path CP '/api/repos/*/commits/*' ).
        DATA lv_commit_repo_name TYPE string.
        DATA lv_commit_oid TYPE string.
        DATA lv_commit_collection TYPE abap_bool.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/commits$' IN lv_path
          SUBMATCHES lv_commit_repo_name.
        IF sy-subrc = 0.
          lv_commit_collection = abap_true.
        ELSE.
          FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/commits/([^/]+)$'
            IN lv_path SUBMATCHES lv_commit_repo_name lv_commit_oid.
        ENDIF.
        DATA(ls_commit_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Commit route was not found.'
          iv_instance = lv_path ).
        IF lv_commit_repo_name IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_commit_problem-content_type ).
          server->response->set_data( ls_commit_problem-body ).
        ELSE.
          DATA(ls_commit_repository) = lo_rest_query->find(
            lv_commit_repo_name ).
          IF ls_commit_repository-id IS INITIAL.
            ls_commit_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_commit_problem-content_type ).
            server->response->set_data( ls_commit_problem-body ).
          ELSE.
            DATA(lo_commit_service) = NEW zcl_hithub_commit_service(
              io_metadata = zcl_hithub_persistence=>metadata_store( )
              io_objects  = zcl_hithub_persistence=>object_store( ) ).
            IF lv_commit_collection = abap_true.
              DATA(lv_commit_ref) = server->request->get_form_field( 'ref' ).
              IF lv_commit_ref IS INITIAL.
                lv_commit_ref = ls_commit_repository-default_branch.
              ENDIF.
              DATA(lt_commit_entries) = lo_commit_service->list(
                iv_repository_id = ls_commit_repository-id
                iv_ref           = lv_commit_ref ).
              server->response->set_status( code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_commit_repr=>list( lt_commit_entries ) ).
            ELSE.
              DATA(lv_commit_algorithm) = COND string(
                WHEN strlen( lv_commit_oid ) = 64 THEN 'sha256'
                ELSE 'sha1' ).
              DATA(ls_commit_entry) = lo_commit_service->read(
                iv_repository_id = ls_commit_repository-id
                iv_algorithm     = lv_commit_algorithm
                iv_oid           = lv_commit_oid ).
              IF ls_commit_entry-oid IS INITIAL.
                ls_commit_problem = zcl_hithub_problem_response=>build(
                  iv_status = 404 iv_detail = 'Commit was not found.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 404 reason = 'Not Found' ).
                server->response->set_content_type(
                  ls_commit_problem-content_type ).
                server->response->set_data( ls_commit_problem-body ).
              ELSE.
                server->response->set_status( code = 200 reason = 'OK' ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_commit_repr=>one( ls_commit_entry ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CS '/contents'.
        DATA lv_contents_repo_name TYPE string.
        DATA lv_contents_path TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/contents(?:/(.*))?$'
          IN lv_path SUBMATCHES lv_contents_repo_name lv_contents_path.
        IF sy-subrc <> 0 OR lv_contents_repo_name IS INITIAL.
          DATA(ls_contents_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Contents route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_contents_problem-content_type ).
          server->response->set_data( ls_contents_problem-body ).
        ELSE.
          DATA(ls_contents_repository) = lo_rest_query->find(
            lv_contents_repo_name ).
          IF ls_contents_repository-id IS INITIAL.
            ls_contents_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_contents_problem-content_type ).
            server->response->set_data( ls_contents_problem-body ).
          ELSE.
            DATA(lv_contents_ref) = server->request->get_form_field( 'ref' ).
            IF lv_contents_ref IS INITIAL.
              lv_contents_ref = ls_contents_repository-default_branch.
            ENDIF.
            DATA(lo_contents_service) = NEW zcl_hithub_contents_service(
              io_metadata = zcl_hithub_persistence=>metadata_store( )
              io_objects  = zcl_hithub_persistence=>object_store( ) ).
            IF server->request->get_form_field( 'format' ) = 'raw'.
              DATA(ls_contents_object) = lo_contents_service->read(
                iv_repository_id = ls_contents_repository-id
                iv_ref = lv_contents_ref iv_path = lv_contents_path ).
              IF ls_contents_object-key-oid IS INITIAL.
                ls_contents_problem = zcl_hithub_problem_response=>build(
                  iv_status = 404 iv_detail = 'File was not found.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 404 reason = 'Not Found' ).
                server->response->set_content_type(
                  ls_contents_problem-content_type ).
                server->response->set_data( ls_contents_problem-body ).
              ELSE.
                server->response->set_status( code = 200 reason = 'OK' ).
                server->response->set_content_type( 'text/plain; charset=utf-8' ).
                server->response->set_data( ls_contents_object-payload ).
              ENDIF.
            ELSE.
              DATA(lt_contents_entries) = lo_contents_service->list(
                iv_repository_id = ls_contents_repository-id
                iv_ref = lv_contents_ref iv_path = lv_contents_path ).
              server->response->set_status( code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_contents_repr=>list( lt_contents_entries ) ).
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET' AND lv_path CP '/api/repos/*/compare'.
        DATA lv_compare_repo_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/compare$' IN lv_path
          SUBMATCHES lv_compare_repo_name.
        DATA(ls_compare_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Comparison route was not found.'
          iv_instance = lv_path ).
        IF sy-subrc <> 0 OR lv_compare_repo_name IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_compare_problem-content_type ).
          server->response->set_data( ls_compare_problem-body ).
        ELSE.
          DATA(ls_compare_repository) = lo_rest_query->find(
            lv_compare_repo_name ).
          IF ls_compare_repository-id IS INITIAL.
            ls_compare_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_compare_problem-content_type ).
            server->response->set_data( ls_compare_problem-body ).
          ELSE.
            DATA(lv_compare_base) = server->request->get_form_field( 'base' ).
            DATA(lv_compare_head) = server->request->get_form_field( 'head' ).
            IF lv_compare_base IS INITIAL.
              lv_compare_base = ls_compare_repository-default_branch.
            ENDIF.
            IF lv_compare_head IS INITIAL.
              lv_compare_head = ls_compare_repository-default_branch.
            ENDIF.
            DATA(lo_compare_service) = NEW zcl_hithub_compare_service(
              io_metadata = zcl_hithub_persistence=>metadata_store( )
              io_objects  = zcl_hithub_persistence=>object_store( ) ).
            DATA(ls_comparison) = lo_compare_service->compare(
              iv_repository_id = ls_compare_repository-id
              iv_base          = lv_compare_base
              iv_head          = lv_compare_head ).
            IF ls_comparison-found = abap_false.
              ls_compare_problem = zcl_hithub_problem_response=>build(
                iv_status = 404 iv_detail = ls_comparison-reason
                iv_instance = lv_path ).
              server->response->set_status( code = 404 reason = 'Not Found' ).
              server->response->set_content_type(
                ls_compare_problem-content_type ).
              server->response->set_data( ls_compare_problem-body ).
            ELSE.
              server->response->set_status( code = 200 reason = 'OK' ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_compare_repr=>one( ls_comparison ) ).
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'GET'.
        DATA lv_rest_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)$' IN lv_path
          SUBMATCHES lv_rest_repository_name.
        IF sy-subrc <> 0 OR lv_rest_repository_name IS INITIAL.
          DATA(ls_rest_query_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Repository route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_rest_query_problem-content_type ).
          server->response->set_data( ls_rest_query_problem-body ).
        ELSE.
          DATA(ls_rest_repository) = lo_rest_query->find(
            lv_rest_repository_name ).
          IF ls_rest_repository-id IS INITIAL.
            ls_rest_query_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_rest_query_problem-content_type ).
            server->response->set_data( ls_rest_query_problem-body ).
          ELSE.
            server->response->set_status(
              code = 200 reason = 'OK' ).
            server->response->set_content_type( 'application/json' ).
            server->response->set_data(
              zcl_hithub_repo_representation=>one_with_readme(
                is_repository = ls_rest_repository
                io_metadata   = zcl_hithub_persistence=>metadata_store( )
                io_objects    = zcl_hithub_persistence=>object_store( ) ) ).
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'PATCH' AND lv_path CS '/pulls/'.
        DATA lv_pr_patch_repo_name TYPE string.
        DATA lv_pr_patch_id TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/pulls/([^/]+)$'
          IN lv_path SUBMATCHES lv_pr_patch_repo_name lv_pr_patch_id.
        IF sy-subrc <> 0 OR lv_pr_patch_repo_name IS INITIAL
            OR lv_pr_patch_id IS INITIAL.
          DATA(ls_pr_patch_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Pull-request route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_pr_patch_problem-content_type ).
          server->response->set_data( ls_pr_patch_problem-body ).
        ELSE.
          DATA(ls_pr_patch_repository) = lo_rest_query->find(
            lv_pr_patch_repo_name ).
          IF ls_pr_patch_repository-id IS INITIAL.
            ls_pr_patch_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_pr_patch_problem-content_type ).
            server->response->set_data( ls_pr_patch_problem-body ).
          ELSE.
            DATA lv_pr_patch_if_match TYPE string.
            DATA lv_pr_patch_expected TYPE int8.
            lv_pr_patch_if_match = server->request->get_header_field(
              'If-Match' ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_pr_patch_if_match WITH ''.
            IF lv_pr_patch_if_match IS INITIAL
                OR lv_pr_patch_if_match CN '0123456789'.
              ls_pr_patch_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current pull-request version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_pr_patch_problem-content_type ).
              server->response->set_data( ls_pr_patch_problem-body ).
            ELSE.
              lv_pr_patch_expected = lv_pr_patch_if_match.
              DATA(ls_pr_patch_document) = zcl_hithub_json=>parse_data(
                server->request->get_data( ) ).
              DATA lv_pr_patch_state TYPE string.
              DATA lv_pr_patch_valid TYPE abap_bool.
              DATA lv_pr_patch_state_seen TYPE abap_bool.
              DATA ls_pr_patch_member TYPE zcl_hithub_json=>ty_member.
              lv_pr_patch_valid = ls_pr_patch_document-valid.
              LOOP AT ls_pr_patch_document-members INTO ls_pr_patch_member.
                IF ls_pr_patch_member-name <> 'state'
                    OR ls_pr_patch_member-kind <> 'string'
                    OR lv_pr_patch_state_seen = abap_true.
                  lv_pr_patch_valid = abap_false.
                ELSE.
                  lv_pr_patch_state = ls_pr_patch_member-value.
                  lv_pr_patch_state_seen = abap_true.
                ENDIF.
              ENDLOOP.
              IF lv_pr_patch_state_seen = abap_false.
                lv_pr_patch_valid = abap_false.
              ENDIF.
              IF lv_pr_patch_valid = abap_false.
                ls_pr_patch_problem = zcl_hithub_problem_response=>build(
                  iv_status   = 400
                  iv_detail   = 'Pull-request patch must contain a string state.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 400 reason = 'Bad Request' ).
                server->response->set_content_type(
                  ls_pr_patch_problem-content_type ).
                server->response->set_data( ls_pr_patch_problem-body ).
              ELSE.
                DATA(ls_pr_patch_result) = zcl_hithub_pull_requests=>transition(
                  iv_repository_id = ls_pr_patch_repository-id
                  iv_id = lv_pr_patch_id iv_state = lv_pr_patch_state
                  iv_expected_version = lv_pr_patch_expected ).
                IF ls_pr_patch_result-success = abap_false.
                  DATA lv_pr_patch_status TYPE i.
                  IF ls_pr_patch_result-reason = 'pull request was not found'.
                    lv_pr_patch_status = 404.
                  ELSEIF ls_pr_patch_result-reason =
                      'pull request version is stale'.
                    lv_pr_patch_status = 412.
                  ELSE.
                    lv_pr_patch_status = 422.
                  ENDIF.
                  ls_pr_patch_problem = zcl_hithub_problem_response=>build(
                    iv_status   = lv_pr_patch_status
                    iv_detail   = ls_pr_patch_result-reason
                    iv_instance = lv_path ).
                  server->response->set_status(
                    code = lv_pr_patch_status reason = 'Pull-Request Update Failed' ).
                  server->response->set_content_type(
                    ls_pr_patch_problem-content_type ).
                  server->response->set_data( ls_pr_patch_problem-body ).
                ELSE.
                  server->response->set_status( code = 200 reason = 'OK' ).
                  server->response->set_content_type( 'application/json' ).
                  server->response->set_data(
                    zcl_hithub_pr_repr=>one(
                      ls_pr_patch_result-pull_request ) ).
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'PATCH' AND lv_path CS '/issues/'.
        DATA lv_issue_patch_repo_name TYPE string.
        DATA lv_issue_patch_id TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/issues/([^/]+)$'
          IN lv_path SUBMATCHES lv_issue_patch_repo_name lv_issue_patch_id.
        DATA(ls_issue_patch_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Issue route was not found.'
          iv_instance = lv_path ).
        IF sy-subrc <> 0 OR lv_issue_patch_repo_name IS INITIAL
            OR lv_issue_patch_id IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_issue_patch_problem-content_type ).
          server->response->set_data( ls_issue_patch_problem-body ).
        ELSE.
          DATA(ls_issue_patch_repository) = lo_rest_query->find(
            lv_issue_patch_repo_name ).
          IF ls_issue_patch_repository-id IS INITIAL.
            ls_issue_patch_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_issue_patch_problem-content_type ).
            server->response->set_data( ls_issue_patch_problem-body ).
          ELSE.
            DATA lv_issue_patch_if_match TYPE string.
            DATA lv_issue_patch_expected TYPE int8.
            lv_issue_patch_if_match = server->request->get_header_field(
              'If-Match' ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_issue_patch_if_match WITH ''.
            IF lv_issue_patch_if_match IS INITIAL
                OR lv_issue_patch_if_match CN '0123456789'.
              ls_issue_patch_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current issue version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_issue_patch_problem-content_type ).
              server->response->set_data( ls_issue_patch_problem-body ).
            ELSE.
              lv_issue_patch_expected = lv_issue_patch_if_match.
              DATA(ls_issue_patch_current) = zcl_hithub_issues=>read(
                iv_repository_id = ls_issue_patch_repository-id
                iv_id            = lv_issue_patch_id ).
              IF ls_issue_patch_current-id IS INITIAL.
                ls_issue_patch_problem = zcl_hithub_problem_response=>build(
                  iv_status = 404 iv_detail = 'Issue was not found.'
                  iv_instance = lv_path ).
                server->response->set_status( code = 404 reason = 'Not Found' ).
                server->response->set_content_type(
                  ls_issue_patch_problem-content_type ).
                server->response->set_data( ls_issue_patch_problem-body ).
              ELSE.
                DATA(ls_issue_patch_document) = zcl_hithub_json=>parse_data(
                  server->request->get_data( ) ).
                DATA lv_issue_patch_valid TYPE abap_bool.
                DATA lv_issue_patch_title TYPE string.
                DATA lv_issue_patch_body TYPE string.
                DATA lv_issue_patch_state TYPE string.
                DATA lv_issue_patch_title_seen TYPE abap_bool.
                DATA lv_issue_patch_body_seen TYPE abap_bool.
                DATA lv_issue_patch_state_seen TYPE abap_bool.
                DATA ls_issue_patch_member TYPE zcl_hithub_json=>ty_member.
                lv_issue_patch_valid = ls_issue_patch_document-valid.
                LOOP AT ls_issue_patch_document-members
                    INTO ls_issue_patch_member.
                  IF ls_issue_patch_member-kind <> 'string'.
                    lv_issue_patch_valid = abap_false.
                    CONTINUE.
                  ENDIF.
                  CASE ls_issue_patch_member-name.
                    WHEN 'title'.
                      IF lv_issue_patch_title_seen = abap_true.
                        lv_issue_patch_valid = abap_false.
                      ELSE.
                        lv_issue_patch_title = ls_issue_patch_member-value.
                        lv_issue_patch_title_seen = abap_true.
                      ENDIF.
                    WHEN 'body'.
                      IF lv_issue_patch_body_seen = abap_true.
                        lv_issue_patch_valid = abap_false.
                      ELSE.
                        lv_issue_patch_body = ls_issue_patch_member-value.
                        lv_issue_patch_body_seen = abap_true.
                      ENDIF.
                    WHEN 'state'.
                      IF lv_issue_patch_state_seen = abap_true.
                        lv_issue_patch_valid = abap_false.
                      ELSE.
                        lv_issue_patch_state = ls_issue_patch_member-value.
                        lv_issue_patch_state_seen = abap_true.
                      ENDIF.
                    WHEN OTHERS.
                      lv_issue_patch_valid = abap_false.
                  ENDCASE.
                ENDLOOP.
                IF lv_issue_patch_title_seen = abap_false
                    AND lv_issue_patch_body_seen = abap_false
                    AND lv_issue_patch_state_seen = abap_false.
                  lv_issue_patch_valid = abap_false.
                ENDIF.
                IF lv_issue_patch_state_seen = abap_true
                    AND ( lv_issue_patch_title_seen = abap_true
                    OR lv_issue_patch_body_seen = abap_true ).
                  lv_issue_patch_valid = abap_false.
                ENDIF.
                IF lv_issue_patch_valid = abap_false.
                  ls_issue_patch_problem = zcl_hithub_problem_response=>build(
                    iv_status   = 400
                    iv_detail   = 'Issue patch contains invalid fields.'
                    iv_instance = lv_path ).
                  server->response->set_status(
                    code = 400 reason = 'Bad Request' ).
                  server->response->set_content_type(
                    ls_issue_patch_problem-content_type ).
                  server->response->set_data( ls_issue_patch_problem-body ).
                ELSE.
                  DATA ls_issue_patch_result TYPE zcl_hithub_issues=>ty_result.
                  IF lv_issue_patch_state_seen = abap_true.
                    ls_issue_patch_result = zcl_hithub_issues=>transition(
                      iv_repository_id    = ls_issue_patch_repository-id
                      iv_id               = lv_issue_patch_id
                      iv_state            = lv_issue_patch_state
                      iv_expected_version = lv_issue_patch_expected ).
                  ELSE.
                    IF lv_issue_patch_title_seen = abap_false.
                      lv_issue_patch_title = ls_issue_patch_current-title.
                    ENDIF.
                    IF lv_issue_patch_body_seen = abap_false.
                      lv_issue_patch_body = ls_issue_patch_current-body.
                    ENDIF.
                    ls_issue_patch_result = zcl_hithub_issues=>update(
                      iv_repository_id    = ls_issue_patch_repository-id
                      iv_id               = lv_issue_patch_id
                      iv_title            = lv_issue_patch_title
                      iv_body             = lv_issue_patch_body
                      iv_expected_version = lv_issue_patch_expected ).
                  ENDIF.
                  IF ls_issue_patch_result-success = abap_false.
                    DATA lv_issue_patch_status TYPE i.
                    IF ls_issue_patch_result-reason = 'issue was not found'.
                      lv_issue_patch_status = 404.
                    ELSEIF ls_issue_patch_result-reason =
                        'issue version is stale'.
                      lv_issue_patch_status = 412.
                    ELSE.
                      lv_issue_patch_status = 422.
                    ENDIF.
                    ls_issue_patch_problem = zcl_hithub_problem_response=>build(
                      iv_status   = lv_issue_patch_status
                      iv_detail   = ls_issue_patch_result-reason
                      iv_instance = lv_path ).
                    server->response->set_status(
                      code = lv_issue_patch_status reason = 'Issue Update Failed' ).
                    server->response->set_content_type(
                      ls_issue_patch_problem-content_type ).
                    server->response->set_data( ls_issue_patch_problem-body ).
                  ELSE.
                    DATA(lo_issue_patch_context) = zcl_hithub_rest_context=>for_local(
                      iv_method = lv_rest_method iv_path = lv_path
                      iv_body = server->request->get_data( )
                      iv_correlation_id = server->request->get_header_field(
                        'X-Request-ID' )
                      iv_if_match = server->request->get_header_field(
                        'If-Match' ) ).
                    zcl_hithub_audit_log=>record(
                      io_sink = lo_audit_sink io_context = lo_issue_patch_context
                      iv_action = COND string( WHEN lv_issue_patch_state_seen = abap_true
                        THEN 'issue.state' ELSE 'issue.update' )
                      iv_subject_type = 'issue' iv_subject_id = lv_issue_patch_id
                      iv_details = |repository={ ls_issue_patch_repository-id }| ).
                    server->response->set_status( code = 200 reason = 'OK' ).
                    server->response->set_content_type( 'application/json' ).
                    server->response->set_data(
                      zcl_hithub_issue_repr=>one(
                        ls_issue_patch_result-issue ) ).
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'PATCH' AND lv_path CS '/branches/'.
        DATA lv_branch_patch_repo_name TYPE string.
        DATA lv_branch_patch_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/branches/(.+)$'
          IN lv_path SUBMATCHES lv_branch_patch_repo_name lv_branch_patch_name.
        IF sy-subrc <> 0 OR lv_branch_patch_repo_name IS INITIAL
            OR lv_branch_patch_name IS INITIAL.
          DATA(ls_branch_patch_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Branch route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_branch_patch_problem-content_type ).
          server->response->set_data( ls_branch_patch_problem-body ).
        ELSE.
          DATA(ls_branch_patch_repository) = lo_rest_query->find(
            lv_branch_patch_repo_name ).
          DATA(lo_branch_patch_service) = NEW zcl_hithub_branch_service(
            io_metadata    = zcl_hithub_persistence=>metadata_store( )
            io_transaction = zcl_hithub_persistence=>transaction( ) ).
          DATA(ls_branch_patch_reference) = lo_branch_patch_service->find(
            iv_repository_id = ls_branch_patch_repository-id
            iv_name          = lv_branch_patch_name ).
          IF ls_branch_patch_repository-id IS INITIAL
              OR ls_branch_patch_reference-name IS INITIAL.
            ls_branch_patch_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Branch was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_branch_patch_problem-content_type ).
            server->response->set_data( ls_branch_patch_problem-body ).
          ELSE.
            DATA(ls_branch_patch_context) = zcl_hithub_rest_context=>for_local(
              iv_method          = lv_rest_method
              iv_path            = lv_path
              iv_body            = server->request->get_data( )
              iv_correlation_id  = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_branch_patch_if_match TYPE string.
            DATA lv_branch_patch_expected TYPE int8.
            lv_branch_patch_if_match = ls_branch_patch_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_branch_patch_if_match WITH ''.
            IF lv_branch_patch_if_match IS INITIAL
                OR lv_branch_patch_if_match CN '0123456789'.
              ls_branch_patch_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current branch version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_branch_patch_problem-content_type ).
              server->response->set_data( ls_branch_patch_problem-body ).
            ELSE.
              lv_branch_patch_expected = lv_branch_patch_if_match.
              DATA(ls_branch_patch_document) = zcl_hithub_json=>parse_data(
                ls_branch_patch_context->body( ) ).
              DATA lv_branch_patch_oid TYPE string.
              DATA lv_branch_patch_valid TYPE abap_bool.
              DATA lv_branch_patch_oid_seen TYPE abap_bool.
              DATA ls_branch_patch_member TYPE zcl_hithub_json=>ty_member.
              lv_branch_patch_valid = ls_branch_patch_document-valid.
              LOOP AT ls_branch_patch_document-members
                  INTO ls_branch_patch_member.
                IF ls_branch_patch_member-name <> 'oid'
                    OR ls_branch_patch_member-kind <> 'string'.
                  lv_branch_patch_valid = abap_false.
                ELSE.
                  lv_branch_patch_oid = ls_branch_patch_member-value.
                  lv_branch_patch_oid_seen = abap_true.
                ENDIF.
              ENDLOOP.
              IF lv_branch_patch_oid_seen = abap_false.
                lv_branch_patch_valid = abap_false.
              ENDIF.
              IF lv_branch_patch_valid = abap_false.
                ls_branch_patch_problem = zcl_hithub_problem_response=>build(
                  iv_status   = 400
                  iv_detail   = 'Request body must contain a string oid.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 400 reason = 'Bad Request' ).
                server->response->set_content_type(
                  ls_branch_patch_problem-content_type ).
                server->response->set_data( ls_branch_patch_problem-body ).
              ELSE.
                DATA(ls_branch_patch_result) = lo_branch_patch_service->update(
                  iv_repository_id    = ls_branch_patch_repository-id
                  iv_name             = lv_branch_patch_name
                  iv_oid              = lv_branch_patch_oid
                  iv_expected_version = lv_branch_patch_expected ).
                IF ls_branch_patch_result-success = abap_false.
                  DATA lv_branch_patch_status TYPE i.
                  IF ls_branch_patch_result-reason = 'branch version is stale'.
                    lv_branch_patch_status = 412.
                  ELSE.
                    lv_branch_patch_status = 422.
                  ENDIF.
                  ls_branch_patch_problem = zcl_hithub_problem_response=>build(
                    iv_status   = lv_branch_patch_status
                    iv_detail   = ls_branch_patch_result-reason
                    iv_instance = lv_path ).
                  server->response->set_status(
                    code = lv_branch_patch_status reason = 'Branch Update Failed' ).
                  server->response->set_content_type(
                    ls_branch_patch_problem-content_type ).
                  server->response->set_data( ls_branch_patch_problem-body ).
                ELSE.
                  zcl_hithub_audit_log=>record(
                    io_sink = lo_audit_sink io_context = ls_branch_patch_context
                    iv_action = 'branch.update' iv_subject_type = 'branch'
                    iv_subject_id = ls_branch_patch_result-reference-name
                    iv_details = |repository={ ls_branch_patch_repository-id }| ).
                  server->response->set_status(
                    code = 200 reason = 'OK' ).
                  server->response->set_content_type( 'application/json' ).
                  server->response->set_data(
                    zcl_hithub_branch_repr=>one(
                      ls_branch_patch_result-reference ) ).
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'PATCH' AND lv_path CS '/tags/'.
        DATA lv_tag_patch_repo_name TYPE string.
        DATA lv_tag_patch_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/tags/(.+)$'
          IN lv_path SUBMATCHES lv_tag_patch_repo_name lv_tag_patch_name.
        IF sy-subrc <> 0 OR lv_tag_patch_repo_name IS INITIAL
            OR lv_tag_patch_name IS INITIAL.
          DATA(ls_tag_patch_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Tag route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_tag_patch_problem-content_type ).
          server->response->set_data( ls_tag_patch_problem-body ).
        ELSE.
          DATA(ls_tag_patch_repository) = lo_rest_query->find(
            lv_tag_patch_repo_name ).
          DATA(lo_tag_patch_service) = NEW zcl_hithub_tag_service(
            io_metadata    = zcl_hithub_persistence=>metadata_store( )
            io_transaction = zcl_hithub_persistence=>transaction( ) ).
          DATA(ls_tag_patch_reference) = lo_tag_patch_service->find(
            iv_repository_id = ls_tag_patch_repository-id
            iv_name          = lv_tag_patch_name ).
          IF ls_tag_patch_repository-id IS INITIAL
              OR ls_tag_patch_reference-name IS INITIAL.
            ls_tag_patch_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Tag was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_tag_patch_problem-content_type ).
            server->response->set_data( ls_tag_patch_problem-body ).
          ELSE.
            DATA(ls_tag_patch_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_tag_patch_if_match TYPE string.
            DATA lv_tag_patch_expected TYPE int8.
            lv_tag_patch_if_match = ls_tag_patch_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_tag_patch_if_match WITH ''.
            IF lv_tag_patch_if_match IS INITIAL
                OR lv_tag_patch_if_match CN '0123456789'.
              ls_tag_patch_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current tag version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_tag_patch_problem-content_type ).
              server->response->set_data( ls_tag_patch_problem-body ).
            ELSE.
              lv_tag_patch_expected = lv_tag_patch_if_match.
              DATA(ls_tag_patch_document) = zcl_hithub_json=>parse_data(
                ls_tag_patch_context->body( ) ).
              DATA lv_tag_patch_oid TYPE string.
              DATA lv_tag_patch_valid TYPE abap_bool.
              DATA lv_tag_patch_oid_seen TYPE abap_bool.
              DATA ls_tag_patch_member TYPE zcl_hithub_json=>ty_member.
              lv_tag_patch_valid = ls_tag_patch_document-valid.
              LOOP AT ls_tag_patch_document-members INTO ls_tag_patch_member.
                IF ls_tag_patch_member-name <> 'oid'
                    OR ls_tag_patch_member-kind <> 'string'.
                  lv_tag_patch_valid = abap_false.
                ELSE.
                  lv_tag_patch_oid = ls_tag_patch_member-value.
                  lv_tag_patch_oid_seen = abap_true.
                ENDIF.
              ENDLOOP.
              IF lv_tag_patch_oid_seen = abap_false.
                lv_tag_patch_valid = abap_false.
              ENDIF.
              IF lv_tag_patch_valid = abap_false.
                ls_tag_patch_problem = zcl_hithub_problem_response=>build(
                  iv_status = 400 iv_detail = 'Request body must contain a string oid.'
                  iv_instance = lv_path ).
                server->response->set_status( code = 400 reason = 'Bad Request' ).
                server->response->set_content_type(
                  ls_tag_patch_problem-content_type ).
                server->response->set_data( ls_tag_patch_problem-body ).
              ELSE.
                DATA(ls_tag_patch_result) = lo_tag_patch_service->update(
                  iv_repository_id = ls_tag_patch_repository-id
                  iv_name = lv_tag_patch_name iv_oid = lv_tag_patch_oid
                  iv_expected_version = lv_tag_patch_expected ).
                IF ls_tag_patch_result-success = abap_false.
                  DATA lv_tag_patch_status TYPE i.
                  IF ls_tag_patch_result-reason = 'tag version is stale'.
                    lv_tag_patch_status = 412.
                  ELSE.
                    lv_tag_patch_status = 422.
                  ENDIF.
                  ls_tag_patch_problem = zcl_hithub_problem_response=>build(
                    iv_status = lv_tag_patch_status
                    iv_detail = ls_tag_patch_result-reason iv_instance = lv_path ).
                  server->response->set_status(
                    code = lv_tag_patch_status reason = 'Tag Update Failed' ).
                  server->response->set_content_type(
                    ls_tag_patch_problem-content_type ).
                  server->response->set_data( ls_tag_patch_problem-body ).
                ELSE.
                  zcl_hithub_audit_log=>record(
                    io_sink = lo_audit_sink io_context = ls_tag_patch_context
                    iv_action = 'tag.update' iv_subject_type = 'tag'
                    iv_subject_id = ls_tag_patch_result-reference-name
                    iv_details = |repository={ ls_tag_patch_repository-id }| ).
                  server->response->set_status( code = 200 reason = 'OK' ).
                  server->response->set_content_type( 'application/json' ).
                  server->response->set_data(
                    zcl_hithub_branch_repr=>one(
                      ls_tag_patch_result-reference ) ).
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'PATCH'.
        DATA lv_patch_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)$' IN lv_path
          SUBMATCHES lv_patch_repository_name.
        IF sy-subrc <> 0 OR lv_patch_repository_name IS INITIAL.
          DATA(ls_patch_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Repository route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_patch_problem-content_type ).
          server->response->set_data( ls_patch_problem-body ).
        ELSE.
          DATA(ls_patch_repository) = lo_rest_query->find(
            lv_patch_repository_name ).
          IF ls_patch_repository-id IS INITIAL.
            ls_patch_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_patch_problem-content_type ).
            server->response->set_data( ls_patch_problem-body ).
          ELSE.
            DATA(lo_patch_context) = zcl_hithub_rest_context=>for_local(
              iv_method          = lv_rest_method
              iv_path            = lv_path
              iv_body            = server->request->get_data( )
              iv_correlation_id  = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_patch_if_match TYPE string.
            DATA lv_patch_expected TYPE int8.
            lv_patch_if_match = lo_patch_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_patch_if_match WITH ''.
            IF lv_patch_if_match IS INITIAL
                OR lv_patch_if_match CN '0123456789'.
              ls_patch_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current repository version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_patch_problem-content_type ).
              server->response->set_data( ls_patch_problem-body ).
            ELSE.
              lv_patch_expected = lv_patch_if_match.
              DATA(ls_patch_document) = zcl_hithub_json=>parse_data(
                lo_patch_context->body( ) ).
              DATA lv_patch_valid TYPE abap_bool.
              DATA lv_patch_description TYPE string.
              DATA lv_patch_branch TYPE string.
              DATA lv_patch_description_seen TYPE abap_bool.
              DATA lv_patch_branch_seen TYPE abap_bool.
              DATA ls_patch_member TYPE zcl_hithub_json=>ty_member.
              lv_patch_valid = ls_patch_document-valid.
              LOOP AT ls_patch_document-members INTO ls_patch_member.
                CASE ls_patch_member-name.
                  WHEN 'description'.
                    IF ls_patch_member-kind <> 'string'.
                      lv_patch_valid = abap_false.
                    ELSE.
                      lv_patch_description = ls_patch_member-value.
                      lv_patch_description_seen = abap_true.
                    ENDIF.
                  WHEN 'default_branch'.
                    IF ls_patch_member-kind <> 'string'.
                      lv_patch_valid = abap_false.
                    ELSE.
                      lv_patch_branch = ls_patch_member-value.
                      lv_patch_branch_seen = abap_true.
                    ENDIF.
                  WHEN 'name'.
                    lv_patch_valid = abap_false.
                  WHEN OTHERS.
                    lv_patch_valid = abap_false.
                ENDCASE.
              ENDLOOP.
              IF lv_patch_description_seen = abap_false
                  AND lv_patch_branch_seen = abap_false.
                lv_patch_valid = abap_false.
              ENDIF.
              IF lv_patch_valid = abap_false.
                ls_patch_problem = zcl_hithub_problem_response=>build(
                  iv_status   = 400
                  iv_detail   = 'Patch body contains invalid or unsupported fields.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 400 reason = 'Bad Request' ).
                server->response->set_content_type(
                  ls_patch_problem-content_type ).
                server->response->set_data( ls_patch_problem-body ).
              ELSE.
                DATA(lo_patch_update) = NEW zcl_hithub_repository_update(
                  io_metadata    = zcl_hithub_persistence=>metadata_store( )
                  io_transaction = zcl_hithub_persistence=>transaction( ) ).
                DATA(ls_patch_result) = lo_patch_update->update(
                  iv_repository_id           = ls_patch_repository-id
                  iv_description             = lv_patch_description
                  iv_description_provided    = lv_patch_description_seen
                  iv_default_branch          = lv_patch_branch
                  iv_default_branch_provided = lv_patch_branch_seen
                  iv_expected_version        = lv_patch_expected ).
                IF ls_patch_result-success = abap_false.
                  DATA lv_patch_status TYPE i.
                  IF ls_patch_result-reason = 'repository was not found'.
                    lv_patch_status = 404.
                  ELSEIF ls_patch_result-reason = 'repository version is stale'.
                    lv_patch_status = 412.
                  ELSE.
                    lv_patch_status = 422.
                  ENDIF.
                  ls_patch_problem = zcl_hithub_problem_response=>build(
                    iv_status   = lv_patch_status
                    iv_detail   = ls_patch_result-reason
                    iv_instance = lv_path ).
                  server->response->set_status(
                    code = lv_patch_status reason = 'Update Failed' ).
                server->response->set_content_type(
                  ls_patch_problem-content_type ).
                server->response->set_data( ls_patch_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = lo_patch_context
                  iv_action = 'repository.update' iv_subject_type = 'repository'
                  iv_subject_id = ls_patch_repository-id ).
                server->response->set_status(
                    code = 200 reason = 'OK' ).
                  server->response->set_content_type( 'application/json' ).
                  server->response->set_data(
                    zcl_hithub_repo_representation=>one(
                      ls_patch_result-repository ) ).
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'DELETE' AND lv_path CS '/branches/'.
        DATA lv_branch_delete_repo_name TYPE string.
        DATA lv_branch_delete_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/branches/(.+)$'
          IN lv_path SUBMATCHES lv_branch_delete_repo_name lv_branch_delete_name.
        IF sy-subrc <> 0 OR lv_branch_delete_repo_name IS INITIAL
            OR lv_branch_delete_name IS INITIAL.
          DATA(ls_branch_delete_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Branch route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_branch_delete_problem-content_type ).
          server->response->set_data( ls_branch_delete_problem-body ).
        ELSE.
          DATA(ls_branch_delete_repository) = lo_rest_query->find(
            lv_branch_delete_repo_name ).
          DATA(lo_branch_delete_service) = NEW zcl_hithub_branch_service(
            io_metadata    = zcl_hithub_persistence=>metadata_store( )
            io_transaction = zcl_hithub_persistence=>transaction( ) ).
          DATA(ls_branch_delete_reference) = lo_branch_delete_service->find(
            iv_repository_id = ls_branch_delete_repository-id
            iv_name          = lv_branch_delete_name ).
          IF ls_branch_delete_repository-id IS INITIAL
              OR ls_branch_delete_reference-name IS INITIAL.
            ls_branch_delete_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Branch was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_branch_delete_problem-content_type ).
            server->response->set_data( ls_branch_delete_problem-body ).
          ELSE.
            DATA(ls_branch_delete_context) = zcl_hithub_rest_context=>for_local(
              iv_method          = lv_rest_method
              iv_path            = lv_path
              iv_body            = server->request->get_data( )
              iv_correlation_id  = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_branch_delete_if_match TYPE string.
            DATA lv_branch_delete_expected TYPE int8.
            lv_branch_delete_if_match = ls_branch_delete_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_branch_delete_if_match WITH ''.
            IF lv_branch_delete_if_match IS INITIAL
                OR lv_branch_delete_if_match CN '0123456789'.
              ls_branch_delete_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current branch version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_branch_delete_problem-content_type ).
              server->response->set_data( ls_branch_delete_problem-body ).
            ELSE.
              lv_branch_delete_expected = lv_branch_delete_if_match.
              DATA(ls_branch_delete_result) = lo_branch_delete_service->delete(
                iv_repository_id    = ls_branch_delete_repository-id
                iv_name             = lv_branch_delete_name
                iv_expected_version = lv_branch_delete_expected ).
              IF ls_branch_delete_result-success = abap_false.
                DATA lv_branch_delete_status TYPE i.
                IF ls_branch_delete_result-reason = 'branch was not found'.
                  lv_branch_delete_status = 404.
                ELSEIF ls_branch_delete_result-reason =
                    'branch version is stale'.
                  lv_branch_delete_status = 412.
                ELSE.
                  lv_branch_delete_status = 422.
                ENDIF.
                ls_branch_delete_problem = zcl_hithub_problem_response=>build(
                  iv_status   = lv_branch_delete_status
                  iv_detail   = ls_branch_delete_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_branch_delete_status reason = 'Branch Delete Failed' ).
                server->response->set_content_type(
                  ls_branch_delete_problem-content_type ).
                server->response->set_data( ls_branch_delete_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = ls_branch_delete_context
                  iv_action = 'branch.delete' iv_subject_type = 'branch'
                  iv_subject_id = ls_branch_delete_reference-name
                  iv_details = |repository={ ls_branch_delete_repository-id }| ).
                server->response->set_status(
                  code = 204 reason = 'No Content' ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'DELETE' AND lv_path CS '/tags/'.
        DATA lv_tag_delete_repo_name TYPE string.
        DATA lv_tag_delete_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/tags/(.+)$'
          IN lv_path SUBMATCHES lv_tag_delete_repo_name lv_tag_delete_name.
        IF sy-subrc <> 0 OR lv_tag_delete_repo_name IS INITIAL
            OR lv_tag_delete_name IS INITIAL.
          DATA(ls_tag_delete_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Tag route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_tag_delete_problem-content_type ).
          server->response->set_data( ls_tag_delete_problem-body ).
        ELSE.
          DATA(ls_tag_delete_repository) = lo_rest_query->find(
            lv_tag_delete_repo_name ).
          DATA(lo_tag_delete_service) = NEW zcl_hithub_tag_service(
            io_metadata    = zcl_hithub_persistence=>metadata_store( )
            io_transaction = zcl_hithub_persistence=>transaction( ) ).
          DATA(ls_tag_delete_reference) = lo_tag_delete_service->find(
            iv_repository_id = ls_tag_delete_repository-id
            iv_name          = lv_tag_delete_name ).
          IF ls_tag_delete_repository-id IS INITIAL
              OR ls_tag_delete_reference-name IS INITIAL.
            ls_tag_delete_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Tag was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_tag_delete_problem-content_type ).
            server->response->set_data( ls_tag_delete_problem-body ).
          ELSE.
            DATA(ls_tag_delete_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_tag_delete_if_match TYPE string.
            DATA lv_tag_delete_expected TYPE int8.
            lv_tag_delete_if_match = ls_tag_delete_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_tag_delete_if_match WITH ''.
            IF lv_tag_delete_if_match IS INITIAL
                OR lv_tag_delete_if_match CN '0123456789'.
              ls_tag_delete_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current tag version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_tag_delete_problem-content_type ).
              server->response->set_data( ls_tag_delete_problem-body ).
            ELSE.
              lv_tag_delete_expected = lv_tag_delete_if_match.
              DATA(ls_tag_delete_result) = lo_tag_delete_service->delete(
                iv_repository_id    = ls_tag_delete_repository-id
                iv_name             = lv_tag_delete_name
                iv_expected_version = lv_tag_delete_expected ).
              IF ls_tag_delete_result-success = abap_false.
                DATA lv_tag_delete_status TYPE i.
                IF ls_tag_delete_result-reason = 'tag was not found'.
                  lv_tag_delete_status = 404.
                ELSEIF ls_tag_delete_result-reason = 'tag version is stale'.
                  lv_tag_delete_status = 412.
                ELSE.
                  lv_tag_delete_status = 422.
                ENDIF.
                ls_tag_delete_problem = zcl_hithub_problem_response=>build(
                  iv_status = lv_tag_delete_status
                  iv_detail = ls_tag_delete_result-reason iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_tag_delete_status reason = 'Tag Delete Failed' ).
                server->response->set_content_type(
                  ls_tag_delete_problem-content_type ).
                server->response->set_data( ls_tag_delete_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = ls_tag_delete_context
                  iv_action = 'tag.delete' iv_subject_type = 'tag'
                  iv_subject_id = ls_tag_delete_reference-name
                  iv_details = |repository={ ls_tag_delete_repository-id }| ).
                server->response->set_status( code = 204 reason = 'No Content' ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'DELETE'.
        DATA lv_delete_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)$' IN lv_path
          SUBMATCHES lv_delete_repository_name.
        IF sy-subrc <> 0 OR lv_delete_repository_name IS INITIAL.
          DATA(ls_delete_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Repository route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_delete_problem-content_type ).
          server->response->set_data( ls_delete_problem-body ).
        ELSE.
          DATA(ls_delete_repository) = lo_rest_query->find(
            lv_delete_repository_name ).
          IF ls_delete_repository-id IS INITIAL.
            ls_delete_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_delete_problem-content_type ).
            server->response->set_data( ls_delete_problem-body ).
          ELSE.
            DATA(lo_delete_context) = zcl_hithub_rest_context=>for_local(
              iv_method          = lv_rest_method
              iv_path            = lv_path
              iv_body            = server->request->get_data( )
              iv_correlation_id  = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_delete_if_match TYPE string.
            DATA lv_delete_expected TYPE int8.
            lv_delete_if_match = lo_delete_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_delete_if_match WITH ''.
            IF lv_delete_if_match IS INITIAL
                OR lv_delete_if_match CN '0123456789'.
              ls_delete_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current repository version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_delete_problem-content_type ).
              server->response->set_data( ls_delete_problem-body ).
            ELSE.
              lv_delete_expected = lv_delete_if_match.
              DATA(lo_delete_service) = NEW zcl_hithub_repository_deletion(
                io_metadata    = zcl_hithub_persistence=>metadata_store( )
                io_transaction = zcl_hithub_persistence=>transaction( ) ).
              DATA(ls_delete_result) = lo_delete_service->delete(
                iv_repository_id    = ls_delete_repository-id
                iv_expected_version = lv_delete_expected ).
              IF ls_delete_result-success = abap_false.
                DATA lv_delete_status TYPE i.
                IF ls_delete_result-reason = 'repository was not found'.
                  lv_delete_status = 404.
                ELSEIF ls_delete_result-reason = 'repository version is stale'.
                  lv_delete_status = 412.
                ELSE.
                  lv_delete_status = 422.
                ENDIF.
                ls_delete_problem = zcl_hithub_problem_response=>build(
                  iv_status   = lv_delete_status
                  iv_detail   = ls_delete_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_delete_status reason = 'Deletion Failed' ).
                server->response->set_content_type(
                  ls_delete_problem-content_type ).
                server->response->set_data( ls_delete_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = lo_delete_context
                  iv_action = 'repository.delete' iv_subject_type = 'repository'
                  iv_subject_id = ls_delete_repository-id ).
                server->response->set_status(
                  code = 204 reason = 'No Content' ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'POST' AND lv_path CS '/tags'.
        DATA lv_tag_post_repo_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/tags$' IN lv_path
          SUBMATCHES lv_tag_post_repo_name.
        IF sy-subrc <> 0 OR lv_tag_post_repo_name IS INITIAL.
          DATA(ls_tag_post_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Tag route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_tag_post_problem-content_type ).
          server->response->set_data( ls_tag_post_problem-body ).
        ELSE.
          DATA(ls_tag_post_repository) = lo_rest_query->find(
            lv_tag_post_repo_name ).
          IF ls_tag_post_repository-id IS INITIAL.
            ls_tag_post_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_tag_post_problem-content_type ).
            server->response->set_data( ls_tag_post_problem-body ).
          ELSE.
            DATA(ls_tag_post_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match = server->request->get_header_field( 'If-Match' ) ).
            DATA(ls_tag_post_document) = zcl_hithub_json=>parse_data(
              ls_tag_post_context->body( ) ).
            DATA lv_tag_post_name TYPE string.
            DATA lv_tag_post_oid TYPE string.
            DATA lv_tag_post_algorithm TYPE string.
            DATA lv_tag_post_valid TYPE abap_bool.
            DATA lv_tag_post_name_seen TYPE abap_bool.
            DATA lv_tag_post_oid_seen TYPE abap_bool.
            DATA ls_tag_post_member TYPE zcl_hithub_json=>ty_member.
            lv_tag_post_algorithm = 'sha1'.
            lv_tag_post_valid = ls_tag_post_document-valid.
            LOOP AT ls_tag_post_document-members INTO ls_tag_post_member.
              CASE ls_tag_post_member-name.
                WHEN 'name'.
                  IF ls_tag_post_member-kind <> 'string'.
                    lv_tag_post_valid = abap_false.
                  ELSE.
                    lv_tag_post_name = ls_tag_post_member-value.
                    lv_tag_post_name_seen = abap_true.
                  ENDIF.
                WHEN 'oid'.
                  IF ls_tag_post_member-kind <> 'string'.
                    lv_tag_post_valid = abap_false.
                  ELSE.
                    lv_tag_post_oid = ls_tag_post_member-value.
                    lv_tag_post_oid_seen = abap_true.
                  ENDIF.
                WHEN 'algorithm'.
                  IF ls_tag_post_member-kind <> 'string'.
                    lv_tag_post_valid = abap_false.
                  ELSE.
                    lv_tag_post_algorithm = ls_tag_post_member-value.
                  ENDIF.
                WHEN OTHERS.
                  lv_tag_post_valid = abap_false.
              ENDCASE.
            ENDLOOP.
            IF lv_tag_post_name_seen = abap_false
                OR lv_tag_post_oid_seen = abap_false.
              lv_tag_post_valid = abap_false.
            ENDIF.
            IF lv_tag_post_valid = abap_false.
              ls_tag_post_problem = zcl_hithub_problem_response=>build(
                iv_status   = 400
                iv_detail   = 'Request body must contain string name and oid.'
                iv_instance = lv_path ).
              server->response->set_status( code = 400 reason = 'Bad Request' ).
              server->response->set_content_type(
                ls_tag_post_problem-content_type ).
              server->response->set_data( ls_tag_post_problem-body ).
            ELSE.
              DATA(lo_tag_post_service) = NEW zcl_hithub_tag_service(
                io_metadata    = zcl_hithub_persistence=>metadata_store( )
                io_transaction = zcl_hithub_persistence=>transaction( ) ).
              DATA(ls_tag_post_result) = lo_tag_post_service->create(
                iv_repository_id = ls_tag_post_repository-id
                iv_name = lv_tag_post_name iv_oid = lv_tag_post_oid
                iv_algorithm = lv_tag_post_algorithm ).
              IF ls_tag_post_result-success = abap_false.
                DATA lv_tag_post_status TYPE i.
                IF ls_tag_post_result-reason = 'tag already exists'.
                  lv_tag_post_status = 409.
                ELSE.
                  lv_tag_post_status = 422.
                ENDIF.
                ls_tag_post_problem = zcl_hithub_problem_response=>build(
                  iv_status = lv_tag_post_status
                  iv_detail = ls_tag_post_result-reason iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_tag_post_status reason = 'Tag Create Failed' ).
                server->response->set_content_type(
                  ls_tag_post_problem-content_type ).
                server->response->set_data( ls_tag_post_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = ls_tag_post_context
                  iv_action = 'tag.create' iv_subject_type = 'tag'
                  iv_subject_id = ls_tag_post_result-reference-name
                  iv_details = |repository={ ls_tag_post_repository-id }| ).
                server->response->set_status( code = 201 reason = 'Created' ).
                server->response->set_header_field(
                  name = 'Location' value = |{ lv_path }/{ lv_tag_post_name }| ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_branch_repr=>one( ls_tag_post_result-reference ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'POST' AND lv_path CS '/branches'.
        DATA lv_branch_post_repo_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/branches$' IN lv_path
          SUBMATCHES lv_branch_post_repo_name.
        IF sy-subrc <> 0 OR lv_branch_post_repo_name IS INITIAL.
          DATA(ls_branch_post_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Branch route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_branch_post_problem-content_type ).
          server->response->set_data( ls_branch_post_problem-body ).
        ELSE.
          DATA(ls_branch_post_repository) = lo_rest_query->find(
            lv_branch_post_repo_name ).
          IF ls_branch_post_repository-id IS INITIAL.
            ls_branch_post_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_branch_post_problem-content_type ).
            server->response->set_data( ls_branch_post_problem-body ).
          ELSE.
            DATA(ls_branch_post_context) = zcl_hithub_rest_context=>for_local(
              iv_method          = lv_rest_method
              iv_path            = lv_path
              iv_body            = server->request->get_data( )
              iv_correlation_id  = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
            DATA(ls_branch_post_document) = zcl_hithub_json=>parse_data(
              ls_branch_post_context->body( ) ).
            DATA lv_branch_post_name TYPE string.
            DATA lv_branch_post_oid TYPE string.
            DATA lv_branch_post_algorithm TYPE string.
            DATA lv_branch_post_valid TYPE abap_bool.
            DATA lv_branch_post_name_seen TYPE abap_bool.
            DATA lv_branch_post_oid_seen TYPE abap_bool.
            DATA ls_branch_post_member TYPE zcl_hithub_json=>ty_member.
            lv_branch_post_algorithm = 'sha1'.
            lv_branch_post_valid = ls_branch_post_document-valid.
            LOOP AT ls_branch_post_document-members INTO ls_branch_post_member.
              CASE ls_branch_post_member-name.
                WHEN 'name'.
                  IF ls_branch_post_member-kind <> 'string'.
                    lv_branch_post_valid = abap_false.
                  ELSE.
                    lv_branch_post_name = ls_branch_post_member-value.
                    lv_branch_post_name_seen = abap_true.
                  ENDIF.
                WHEN 'oid'.
                  IF ls_branch_post_member-kind <> 'string'.
                    lv_branch_post_valid = abap_false.
                  ELSE.
                    lv_branch_post_oid = ls_branch_post_member-value.
                    lv_branch_post_oid_seen = abap_true.
                  ENDIF.
                WHEN 'algorithm'.
                  IF ls_branch_post_member-kind <> 'string'.
                    lv_branch_post_valid = abap_false.
                  ELSE.
                    lv_branch_post_algorithm = ls_branch_post_member-value.
                  ENDIF.
                WHEN OTHERS.
                  lv_branch_post_valid = abap_false.
              ENDCASE.
            ENDLOOP.
            IF lv_branch_post_name_seen = abap_false
                OR lv_branch_post_oid_seen = abap_false.
              lv_branch_post_valid = abap_false.
            ENDIF.
            IF lv_branch_post_valid = abap_false.
              ls_branch_post_problem = zcl_hithub_problem_response=>build(
                iv_status   = 400
                iv_detail   = 'Request body must contain string name and oid.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 400 reason = 'Bad Request' ).
              server->response->set_content_type(
                ls_branch_post_problem-content_type ).
              server->response->set_data( ls_branch_post_problem-body ).
            ELSE.
              DATA(lo_branch_post_service) = NEW zcl_hithub_branch_service(
                io_metadata    = zcl_hithub_persistence=>metadata_store( )
                io_transaction = zcl_hithub_persistence=>transaction( ) ).
              DATA(ls_branch_post_result) = lo_branch_post_service->create(
                iv_repository_id = ls_branch_post_repository-id
                iv_name          = lv_branch_post_name
                iv_oid           = lv_branch_post_oid
                iv_algorithm     = lv_branch_post_algorithm ).
              IF ls_branch_post_result-success = abap_false.
                DATA lv_branch_post_status TYPE i.
                IF ls_branch_post_result-reason = 'branch already exists'.
                  lv_branch_post_status = 409.
                ELSE.
                  lv_branch_post_status = 422.
                ENDIF.
                ls_branch_post_problem = zcl_hithub_problem_response=>build(
                  iv_status   = lv_branch_post_status
                  iv_detail   = ls_branch_post_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_branch_post_status reason = 'Branch Create Failed' ).
                server->response->set_content_type(
                  ls_branch_post_problem-content_type ).
                server->response->set_data( ls_branch_post_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = ls_branch_post_context
                  iv_action = 'branch.create' iv_subject_type = 'branch'
                  iv_subject_id = ls_branch_post_result-reference-name
                  iv_details = |repository={ ls_branch_post_repository-id }| ).
                server->response->set_status(
                  code = 201 reason = 'Created' ).
                server->response->set_header_field(
                  name  = 'Location'
                  value = |{ lv_path }/{ lv_branch_post_name }| ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_branch_repr=>one(
                    ls_branch_post_result-reference ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'POST' AND lv_path CS '/issues'.
        DATA lv_issue_post_repo_name TYPE string.
        DATA lv_issue_post_id TYPE string.
        DATA lv_issue_post_comment TYPE abap_bool.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/issues/([^/]+)/comments$'
          IN lv_path SUBMATCHES lv_issue_post_repo_name lv_issue_post_id.
        IF sy-subrc = 0.
          lv_issue_post_comment = abap_true.
        ELSE.
          FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/issues$' IN lv_path
            SUBMATCHES lv_issue_post_repo_name.
        ENDIF.
        DATA(ls_issue_post_problem) = zcl_hithub_problem_response=>build(
          iv_status = 404 iv_detail = 'Issue route was not found.'
          iv_instance = lv_path ).
        IF lv_issue_post_repo_name IS INITIAL.
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_issue_post_problem-content_type ).
          server->response->set_data( ls_issue_post_problem-body ).
        ELSE.
          DATA(ls_issue_post_repository) = lo_rest_query->find(
            lv_issue_post_repo_name ).
          IF ls_issue_post_repository-id IS INITIAL.
            ls_issue_post_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_issue_post_problem-content_type ).
            server->response->set_data( ls_issue_post_problem-body ).
          ELSEIF lv_issue_post_comment = abap_true.
            DATA(lo_issue_comment_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' ) ).
            DATA(ls_issue_comment_document) = zcl_hithub_json=>parse_data(
              lo_issue_comment_context->body( ) ).
            DATA ls_issue_comment TYPE zcl_hithub_issue_comments=>ty_comment.
            DATA lv_issue_comment_valid TYPE abap_bool.
            DATA lv_issue_comment_id_seen TYPE abap_bool.
            DATA lv_issue_comment_body_seen TYPE abap_bool.
            DATA ls_issue_comment_member TYPE zcl_hithub_json=>ty_member.
            lv_issue_comment_valid = ls_issue_comment_document-valid.
            ls_issue_comment-repository_id = ls_issue_post_repository-id.
            ls_issue_comment-issue_id = lv_issue_post_id.
            ls_issue_comment-actor = lo_issue_comment_context->actor_label( ).
            GET TIME STAMP FIELD ls_issue_comment-created_at.
            LOOP AT ls_issue_comment_document-members
                INTO ls_issue_comment_member.
              IF ls_issue_comment_member-kind <> 'string'.
                lv_issue_comment_valid = abap_false.
                CONTINUE.
              ENDIF.
              CASE ls_issue_comment_member-name.
                WHEN 'id'.
                  IF lv_issue_comment_id_seen = abap_true.
                    lv_issue_comment_valid = abap_false.
                  ELSE.
                    ls_issue_comment-comment_id =
                      ls_issue_comment_member-value.
                    lv_issue_comment_id_seen = abap_true.
                  ENDIF.
                WHEN 'body'.
                  IF lv_issue_comment_body_seen = abap_true.
                    lv_issue_comment_valid = abap_false.
                  ELSE.
                    ls_issue_comment-body = ls_issue_comment_member-value.
                    lv_issue_comment_body_seen = abap_true.
                  ENDIF.
                WHEN OTHERS.
                  lv_issue_comment_valid = abap_false.
              ENDCASE.
            ENDLOOP.
            IF lv_issue_comment_id_seen = abap_false
                OR lv_issue_comment_body_seen = abap_false.
              lv_issue_comment_valid = abap_false.
            ENDIF.
            IF lv_issue_comment_valid = abap_false.
              ls_issue_post_problem = zcl_hithub_problem_response=>build(
                iv_status   = 400
                iv_detail   = 'Comment body must contain string id and body.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 400 reason = 'Bad Request' ).
              server->response->set_content_type(
                ls_issue_post_problem-content_type ).
              server->response->set_data( ls_issue_post_problem-body ).
            ELSEIF zcl_hithub_issue_comments=>add( ls_issue_comment ) = abap_false.
              ls_issue_post_problem = zcl_hithub_problem_response=>build(
                iv_status = 409 iv_detail = 'Comment already exists.'
                iv_instance = lv_path ).
              server->response->set_status( code = 409 reason = 'Conflict' ).
              server->response->set_content_type(
                ls_issue_post_problem-content_type ).
              server->response->set_data( ls_issue_post_problem-body ).
            ELSE.
              zcl_hithub_audit_log=>record(
                io_sink = lo_audit_sink io_context = lo_issue_comment_context
                iv_action = 'issue.comment' iv_subject_type = 'issue'
                iv_subject_id = lv_issue_post_id
                iv_details = |repository={ ls_issue_post_repository-id }| ).
              DATA lt_issue_comment_response TYPE zcl_hithub_json=>ty_members.
              APPEND VALUE #( name = 'id' kind = 'string'
                value = ls_issue_comment-comment_id )
                TO lt_issue_comment_response.
              APPEND VALUE #( name = 'actor' kind = 'string'
                value = ls_issue_comment-actor ) TO lt_issue_comment_response.
              APPEND VALUE #( name = 'body' kind = 'string'
                value = ls_issue_comment-body ) TO lt_issue_comment_response.
              APPEND VALUE #( name = 'created_at' kind = 'string'
                value = ls_issue_comment-created_at )
                TO lt_issue_comment_response.
              server->response->set_status( code = 201 reason = 'Created' ).
              server->response->set_header_field(
                name = 'Location' value = lv_path && '/' &&
                ls_issue_comment-comment_id ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data( zcl_hithub_json=>serialize_data(
                lt_issue_comment_response ) ).
            ENDIF.
          ELSE.
            DATA(lo_issue_post_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' ) ).
            DATA(ls_issue_post_document) = zcl_hithub_json=>parse_data(
              lo_issue_post_context->body( ) ).
            DATA ls_issue_post TYPE zcl_hithub_issues=>ty_issue.
            DATA lv_issue_post_valid TYPE abap_bool.
            DATA lv_issue_post_title_seen TYPE abap_bool.
            DATA ls_issue_post_member TYPE zcl_hithub_json=>ty_member.
            DATA lv_issue_post_key TYPE string.
            DATA lv_issue_post_replay TYPE string.
            DATA lo_issue_post_store TYPE REF TO zif_hithub_metadata_store.
            lv_issue_post_valid = ls_issue_post_document-valid.
            ls_issue_post-repository_id = ls_issue_post_repository-id.
            ls_issue_post-actor = lo_issue_post_context->actor_label( ).
            LOOP AT ls_issue_post_document-members INTO ls_issue_post_member.
              IF ls_issue_post_member-kind <> 'string'.
                lv_issue_post_valid = abap_false.
                CONTINUE.
              ENDIF.
              CASE ls_issue_post_member-name.
                WHEN 'title'.
                  IF lv_issue_post_title_seen = abap_true.
                    lv_issue_post_valid = abap_false.
                  ELSE.
                    ls_issue_post-title = ls_issue_post_member-value.
                    lv_issue_post_title_seen = abap_true.
                  ENDIF.
                WHEN 'body'.
                  ls_issue_post-body = ls_issue_post_member-value.
                WHEN OTHERS.
                  lv_issue_post_valid = abap_false.
              ENDCASE.
            ENDLOOP.
            IF lv_issue_post_title_seen = abap_false.
              lv_issue_post_valid = abap_false.
            ENDIF.
            lv_issue_post_key = lo_issue_post_context->idempotency_key( ).
            lo_issue_post_store = zcl_hithub_persistence=>metadata_store( ).
            IF lv_issue_post_valid = abap_true
                AND lv_issue_post_key IS NOT INITIAL.
              lv_issue_post_replay = lo_issue_post_store->read_idempotency(
                iv_actor = ls_issue_post-actor
                iv_key   = |issue:{ ls_issue_post_repository-id }:{ lv_issue_post_key }| ).
            ENDIF.
            IF lv_issue_post_valid = abap_false.
              ls_issue_post_problem = zcl_hithub_problem_response=>build(
                iv_status   = 400
                iv_detail   = 'Issue body must contain a string title.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 400 reason = 'Bad Request' ).
              server->response->set_content_type(
                ls_issue_post_problem-content_type ).
              server->response->set_data( ls_issue_post_problem-body ).
            ELSEIF lv_issue_post_replay IS NOT INITIAL.
              DATA(ls_issue_post_replayed) = zcl_hithub_issues=>read(
                iv_repository_id = ls_issue_post_repository-id
                iv_id            = lv_issue_post_replay ).
              server->response->set_status( code = 201 reason = 'Created' ).
              server->response->set_header_field(
                name = 'Location' value = lv_path && '/' &&
                ls_issue_post_replayed-id ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_issue_repr=>one( ls_issue_post_replayed ) ).
            ELSE.
              DATA(ls_issue_post_result) = zcl_hithub_issues=>create(
                ls_issue_post ).
              IF ls_issue_post_result-success = abap_false.
                DATA lv_issue_post_status TYPE i.
                IF ls_issue_post_result-reason = 'issue already exists'.
                  lv_issue_post_status = 409.
                ELSE.
                  lv_issue_post_status = 422.
                ENDIF.
                ls_issue_post_problem = zcl_hithub_problem_response=>build(
                  iv_status   = lv_issue_post_status
                  iv_detail   = ls_issue_post_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_issue_post_status reason = 'Issue Create Failed' ).
                server->response->set_content_type(
                  ls_issue_post_problem-content_type ).
                server->response->set_data( ls_issue_post_problem-body ).
              ELSE.
                IF lv_issue_post_key IS NOT INITIAL.
                  lo_issue_post_store->save_idempotency(
                    iv_actor      = ls_issue_post-actor
                    iv_key        = |issue:{ ls_issue_post_repository-id }:{ lv_issue_post_key }|
                    iv_subject_id = ls_issue_post_result-issue-id ).
                ENDIF.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = lo_issue_post_context
                  iv_action = 'issue.create' iv_subject_type = 'issue'
                  iv_subject_id = ls_issue_post_result-issue-id
                  iv_details = |repository={ ls_issue_post_repository-id }| ).
                server->response->set_status( code = 201 reason = 'Created' ).
                server->response->set_header_field(
                  name = 'Location' value = lv_path && '/' &&
                  ls_issue_post_result-issue-id ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_issue_repr=>one( ls_issue_post_result-issue ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'POST' AND lv_path CS '/pulls'.
        DATA lv_pr_post_repo_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/pulls$' IN lv_path
          SUBMATCHES lv_pr_post_repo_name.
        IF sy-subrc <> 0 OR lv_pr_post_repo_name IS INITIAL.
          DATA(ls_pr_post_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404 iv_detail = 'Pull-request route was not found.'
            iv_instance = lv_path ).
          server->response->set_status( code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_pr_post_problem-content_type ).
          server->response->set_data( ls_pr_post_problem-body ).
        ELSE.
          DATA(ls_pr_post_repository) = lo_rest_query->find(
            lv_pr_post_repo_name ).
          IF ls_pr_post_repository-id IS INITIAL.
            ls_pr_post_problem = zcl_hithub_problem_response=>build(
              iv_status = 404 iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status( code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_pr_post_problem-content_type ).
            server->response->set_data( ls_pr_post_problem-body ).
          ELSE.
            DATA(lo_pr_post_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' ) ).
            DATA(ls_pr_post_document) = zcl_hithub_json=>parse_data(
              lo_pr_post_context->body( ) ).
            DATA ls_pr_post_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
            DATA lv_pr_post_valid TYPE abap_bool.
            DATA lv_pr_post_source_seen TYPE abap_bool.
            DATA lv_pr_post_target_seen TYPE abap_bool.
            DATA lv_pr_post_base_seen TYPE abap_bool.
            DATA lv_pr_post_head_seen TYPE abap_bool.
            DATA ls_pr_post_member TYPE zcl_hithub_json=>ty_member.
            DATA lv_pr_post_key TYPE string.
            DATA lv_pr_post_replay TYPE string.
            DATA lo_pr_post_store TYPE REF TO zif_hithub_metadata_store.
            lv_pr_post_valid = ls_pr_post_document-valid.
            ls_pr_post_request-repository_id = ls_pr_post_repository-id.
            ls_pr_post_request-state = zcl_hithub_pull_request_state=>c_draft.
            LOOP AT ls_pr_post_document-members INTO ls_pr_post_member.
              IF ls_pr_post_member-kind <> 'string'.
                lv_pr_post_valid = abap_false.
                CONTINUE.
              ENDIF.
              CASE ls_pr_post_member-name.
                WHEN 'state'.
                  ls_pr_post_request-state = ls_pr_post_member-value.
                WHEN 'source_ref'.
                  ls_pr_post_request-source_ref = ls_pr_post_member-value.
                  lv_pr_post_source_seen = abap_true.
                WHEN 'target_ref'.
                  ls_pr_post_request-target_ref = ls_pr_post_member-value.
                  lv_pr_post_target_seen = abap_true.
                WHEN 'base_oid'.
                  ls_pr_post_request-base_oid = ls_pr_post_member-value.
                  lv_pr_post_base_seen = abap_true.
                WHEN 'head_oid'.
                  ls_pr_post_request-head_oid = ls_pr_post_member-value.
                  lv_pr_post_head_seen = abap_true.
                WHEN OTHERS.
                  lv_pr_post_valid = abap_false.
              ENDCASE.
            ENDLOOP.
            IF lv_pr_post_source_seen = abap_false
                OR lv_pr_post_target_seen = abap_false
                OR lv_pr_post_base_seen = abap_false
                OR lv_pr_post_head_seen = abap_false.
              lv_pr_post_valid = abap_false.
            ENDIF.
            lv_pr_post_key = lo_pr_post_context->idempotency_key( ).
            lo_pr_post_store = zcl_hithub_persistence=>metadata_store( ).
            IF lv_pr_post_valid = abap_true AND lv_pr_post_key IS NOT INITIAL.
              lv_pr_post_replay = lo_pr_post_store->read_idempotency(
                iv_actor = lo_pr_post_context->actor_label( )
                iv_key   = |pull:{ ls_pr_post_repository-id }:{ lv_pr_post_key }| ).
            ENDIF.
            IF lv_pr_post_valid = abap_false.
              ls_pr_post_problem = zcl_hithub_problem_response=>build(
                iv_status   = 400
                iv_detail   = 'Pull-request body contains invalid fields.'
                iv_instance = lv_path ).
              server->response->set_status( code = 400 reason = 'Bad Request' ).
              server->response->set_content_type(
                ls_pr_post_problem-content_type ).
              server->response->set_data( ls_pr_post_problem-body ).
            ELSEIF lv_pr_post_replay IS NOT INITIAL.
              DATA(ls_pr_post_replayed) = zcl_hithub_pull_requests=>find(
                iv_repository_id = ls_pr_post_repository-id
                iv_id            = lv_pr_post_replay ).
              server->response->set_status( code = 201 reason = 'Created' ).
              server->response->set_header_field(
                name  = 'Location'
                value = |/api/repos/{ lv_pr_post_repo_name }/pulls/{ ls_pr_post_replayed-id }| ).
              server->response->set_content_type( 'application/json' ).
              server->response->set_data(
                zcl_hithub_pr_repr=>one( ls_pr_post_replayed ) ).
            ELSE.
              DATA(ls_pr_post_result) = zcl_hithub_pull_requests=>create(
                ls_pr_post_request ).
              IF ls_pr_post_result-success = abap_false.
                ls_pr_post_problem = zcl_hithub_problem_response=>build(
                  iv_status = 409 iv_detail = ls_pr_post_result-reason
                  iv_instance = lv_path ).
                server->response->set_status( code = 409 reason = 'Conflict' ).
                server->response->set_content_type(
                  ls_pr_post_problem-content_type ).
                server->response->set_data( ls_pr_post_problem-body ).
              ELSE.
                IF lv_pr_post_key IS NOT INITIAL.
                  lo_pr_post_store->save_idempotency(
                    iv_actor      = lo_pr_post_context->actor_label( )
                    iv_key        = |pull:{ ls_pr_post_repository-id }:{ lv_pr_post_key }|
                    iv_subject_id = ls_pr_post_result-pull_request-id ).
                ENDIF.
                server->response->set_status( code = 201 reason = 'Created' ).
                server->response->set_header_field(
                  name  = 'Location'
                  value = |/api/repos/{ lv_pr_post_repo_name }/pulls/{ ls_pr_post_result-pull_request-id }| ).
                server->response->set_content_type( 'application/json' ).
                server->response->set_data(
                  zcl_hithub_pr_repr=>one( ls_pr_post_result-pull_request ) ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'POST' AND lv_path <> '/api/repos'.
        DATA lv_purge_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)/purge$' IN lv_path
          SUBMATCHES lv_purge_repository_name.
        IF sy-subrc <> 0 OR lv_purge_repository_name IS INITIAL.
          DATA(ls_purge_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 404
            iv_detail   = 'Repository purge route was not found.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = 404 reason = 'Not Found' ).
          server->response->set_content_type(
            ls_purge_problem-content_type ).
          server->response->set_data( ls_purge_problem-body ).
        ELSE.
          DATA(ls_purge_repository) = lo_rest_query->find(
            iv_name            = lv_purge_repository_name
            iv_include_deleted = abap_true ).
          IF ls_purge_repository-id IS INITIAL.
            ls_purge_problem = zcl_hithub_problem_response=>build(
              iv_status   = 404
              iv_detail   = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_purge_problem-content_type ).
            server->response->set_data( ls_purge_problem-body ).
          ELSE.
            DATA(lo_purge_context) = zcl_hithub_rest_context=>for_local(
              iv_method          = lv_rest_method
              iv_path            = lv_path
              iv_body            = server->request->get_data( )
              iv_correlation_id  = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_purge_if_match TYPE string.
            DATA lv_purge_expected TYPE int8.
            lv_purge_if_match = lo_purge_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_purge_if_match WITH ''.
            IF lv_purge_if_match IS INITIAL
                OR lv_purge_if_match CN '0123456789'.
              ls_purge_problem = zcl_hithub_problem_response=>build(
                iv_status   = 428
                iv_detail   = 'If-Match must contain the current repository version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_purge_problem-content_type ).
              server->response->set_data( ls_purge_problem-body ).
            ELSE.
              lv_purge_expected = lv_purge_if_match.
              DATA(lo_purge_service) = NEW zcl_hithub_repository_purge(
                io_metadata    = zcl_hithub_persistence=>metadata_store( )
                io_objects     = zcl_hithub_persistence=>object_store( )
                io_transaction = zcl_hithub_persistence=>transaction( ) ).
              DATA(ls_purge_result) = lo_purge_service->purge(
                iv_repository_id    = ls_purge_repository-id
                iv_expected_version = lv_purge_expected ).
              IF ls_purge_result-success = abap_false.
                DATA lv_purge_status TYPE i.
                IF ls_purge_result-reason = 'repository was not found'.
                  lv_purge_status = 404.
                ELSEIF ls_purge_result-reason = 'repository version is stale'.
                  lv_purge_status = 412.
                ELSEIF ls_purge_result-reason =
                    'repository must be soft deleted first'.
                  lv_purge_status = 409.
                ELSE.
                  lv_purge_status = 422.
                ENDIF.
                ls_purge_problem = zcl_hithub_problem_response=>build(
                  iv_status   = lv_purge_status
                  iv_detail   = ls_purge_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_purge_status reason = 'Purge Failed' ).
                server->response->set_content_type(
                  ls_purge_problem-content_type ).
                server->response->set_data( ls_purge_problem-body ).
              ELSE.
                zcl_hithub_audit_log=>record(
                  io_sink = lo_audit_sink io_context = lo_purge_context
                  iv_action = 'repository.purge' iv_subject_type = 'repository'
                  iv_subject_id = ls_purge_repository-id ).
                server->response->set_status(
                  code = 204 reason = 'No Content' ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_path = '/api/repos' AND lv_rest_method = 'POST'.
        DATA(lo_rest_context) = zcl_hithub_rest_context=>for_local(
          iv_method          = lv_rest_method
          iv_path            = lv_path
          iv_body            = server->request->get_data( )
          iv_correlation_id  = server->request->get_header_field(
            'X-Request-ID' )
          iv_idempotency_key = server->request->get_header_field(
            'Idempotency-Key' )
          iv_if_match        = server->request->get_header_field( 'If-Match' ) ).
        DATA(ls_rest_document) = zcl_hithub_json=>parse_data(
          lo_rest_context->body( ) ).
        DATA lv_rest_name TYPE string.
        DATA lv_rest_description TYPE string.
        DATA lv_rest_default_branch TYPE string.
        DATA lv_rest_name_seen TYPE abap_bool.
        DATA lv_rest_body_valid TYPE abap_bool.
        DATA ls_rest_member TYPE zcl_hithub_json=>ty_member.
        lv_rest_body_valid = ls_rest_document-valid.
        LOOP AT ls_rest_document-members INTO ls_rest_member.
          CASE ls_rest_member-name.
            WHEN 'name'.
              IF ls_rest_member-kind <> 'string'.
                lv_rest_body_valid = abap_false.
              ELSE.
                lv_rest_name = ls_rest_member-value.
                lv_rest_name_seen = abap_true.
              ENDIF.
            WHEN 'description'.
              IF ls_rest_member-kind <> 'string'.
                lv_rest_body_valid = abap_false.
              ELSE.
                lv_rest_description = ls_rest_member-value.
              ENDIF.
            WHEN 'default_branch'.
              IF ls_rest_member-kind <> 'string'.
                lv_rest_body_valid = abap_false.
              ELSE.
                lv_rest_default_branch = ls_rest_member-value.
              ENDIF.
          ENDCASE.
        ENDLOOP.
        IF lv_rest_name_seen = abap_false.
          lv_rest_body_valid = abap_false.
        ENDIF.
        IF lv_rest_body_valid = abap_true.
          DATA(lo_rest_metadata) = zcl_hithub_persistence=>metadata_store( ).
          DATA(lo_rest_transaction) = zcl_hithub_persistence=>transaction( ).
          DATA(lo_rest_identity) = NEW zcl_hithub_system_identity( ).
          DATA(lo_rest_creation) = NEW zcl_hithub_repository_creation(
            io_metadata    = lo_rest_metadata
            io_objects     = zcl_hithub_persistence=>object_store( )
            io_transaction = lo_rest_transaction
            io_identity    = lo_rest_identity ).
          DATA(ls_rest_result) = lo_rest_creation->create(
            iv_name            = lv_rest_name
            iv_description     = lv_rest_description
            iv_default_branch  = lv_rest_default_branch
            iv_actor           = lo_rest_context->actor_label( )
            iv_idempotency_key = lo_rest_context->idempotency_key( ) ).
        ENDIF.
        IF lv_rest_body_valid = abap_false.
          DATA(ls_rest_problem) = zcl_hithub_problem_response=>build(
            iv_status   = 400
            iv_detail   = 'Request body must be a JSON object with a string name.'
            iv_instance = lv_path ).
          server->response->set_status(
            code = ls_rest_problem-status reason = 'Bad Request' ).
          server->response->set_content_type(
            ls_rest_problem-content_type ).
          server->response->set_data( ls_rest_problem-body ).
        ELSEIF ls_rest_result-success = abap_false.
          DATA lv_rest_status TYPE i.
          IF ls_rest_result-reason = 'repository already exists'.
            lv_rest_status = 409.
          ELSE.
            lv_rest_status = 422.
          ENDIF.
          ls_rest_problem = zcl_hithub_problem_response=>build(
            iv_status   = lv_rest_status
            iv_detail   = ls_rest_result-reason
            iv_instance = lv_path ).
          server->response->set_status(
            code = ls_rest_problem-status reason = 'Request Failed' ).
          server->response->set_content_type(
            ls_rest_problem-content_type ).
          server->response->set_data( ls_rest_problem-body ).
        ELSE.
          zcl_hithub_audit_log=>record(
            io_sink = lo_audit_sink io_context = lo_rest_context
            iv_action = 'repository.create' iv_subject_type = 'repository'
            iv_subject_id = ls_rest_result-repository-id
            iv_details = |name={ ls_rest_result-repository-name }| ).
          DATA lt_rest_members TYPE zcl_hithub_json=>ty_members.
          DATA ls_rest_output TYPE zcl_hithub_json=>ty_member.
          DATA lv_rest_version TYPE string.
          ls_rest_output-name = 'id'.
          ls_rest_output-kind = 'string'.
          ls_rest_output-value = ls_rest_result-repository-id.
          APPEND ls_rest_output TO lt_rest_members.
          CLEAR ls_rest_output.
          ls_rest_output-name = 'name'.
          ls_rest_output-kind = 'string'.
          ls_rest_output-value = ls_rest_result-repository-name.
          APPEND ls_rest_output TO lt_rest_members.
          CLEAR ls_rest_output.
          ls_rest_output-name = 'description'.
          ls_rest_output-kind = 'string'.
          ls_rest_output-value = ls_rest_result-repository-description.
          APPEND ls_rest_output TO lt_rest_members.
          CLEAR ls_rest_output.
          ls_rest_output-name = 'default_branch'.
          ls_rest_output-kind = 'string'.
          ls_rest_output-value =
            ls_rest_result-repository-default_branch.
          APPEND ls_rest_output TO lt_rest_members.
          CLEAR ls_rest_output.
          ls_rest_output-name = 'version'.
          ls_rest_output-kind = 'number'.
          lv_rest_version = |{ ls_rest_result-repository-version }|.
          ls_rest_output-value = lv_rest_version.
          APPEND ls_rest_output TO lt_rest_members.
          server->response->set_status(
            code = 201 reason = 'Created' ).
          server->response->set_header_field(
            name  = 'Location'
            value = |/api/repos/{ ls_rest_result-repository-name }| ).
          server->response->set_content_type( 'application/json' ).
          server->response->set_data(
            zcl_hithub_json=>serialize_data( lt_rest_members ) ).
        ENDIF.
      ELSE.
        DATA(ls_method_problem) = zcl_hithub_problem_response=>build(
          iv_status   = 501
          iv_detail   = 'This REST route is not implemented yet.'
          iv_instance = lv_path ).
        server->response->set_status(
          code = ls_method_problem-status reason = 'Not Implemented' ).
        server->response->set_content_type(
          ls_method_problem-content_type ).
        server->response->set_data( ls_method_problem-body ).
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
