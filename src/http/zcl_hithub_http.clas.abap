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
      DATA(lo_upload_metadata) = NEW zcl_hithub_local_meta_store( ).

      IF ls_route-kind = 'git-receive-pack'.
        lv_receive_request = abap_true.
        lv_service = 'git-receive-pack'.
      ENDIF.

      lv_upload_repository_name = ls_route-repository_name.
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
      IF lv_receive_request = abap_true.
        ls_receive_request = zcl_hithub_receive_request=>parse(
          server->request->get_data( ) ).
        IF ls_upload_repository-id IS NOT INITIAL
            AND ls_receive_request-valid = abap_true.
          lv_receive_ok = abap_true.
          IF lines( ls_receive_request-commands ) > 1.
            DATA(lo_batch_store) = NEW zcl_hithub_local_object_store( ).
            DATA(lo_batch_reader) = NEW zcl_hithub_object_reader(
              lo_batch_store ).
            DATA(lo_batch_base) = NEW zcl_hithub_pack_base_resolver(
              lo_batch_reader ).
            DATA(lo_batch_compression) =
              NEW zcl_hithub_abap_compression( ).
            DATA(lo_batch_codec) = NEW zcl_hithub_pack_codec(
              io_compression = lo_batch_compression
              io_base_resolver = lo_batch_base ).
            DATA(lo_batch_transaction) = NEW zcl_hithub_local_unit_work( ).
            DATA(lo_batch) = NEW zcl_hithub_receive_batch(
              io_store = lo_batch_store io_metadata = lo_upload_metadata
              io_codec = lo_batch_codec io_transaction = lo_batch_transaction ).
            lo_batch->apply(
              EXPORTING
                iv_repository_id = ls_upload_repository-id
                iv_pack = ls_receive_request-pack
                it_commands = ls_receive_request-commands
              IMPORTING
                et_results = lt_receive_results
                rv_success = lv_receive_ok ).
          ELSE.
          LOOP AT ls_receive_request-commands INTO ls_receive_command.
            CLEAR ls_receive_result.
            ls_receive_result-ref_name = ls_receive_command-ref_name.
            ls_receive_current =
              lo_upload_metadata->zif_hithub_metadata_store~read_reference(
                iv_repository_id = ls_upload_repository-id
                iv_name = ls_receive_command-ref_name ).
            IF zcl_hithub_ref_update_policy=>old_oid_matches(
                io_metadata = lo_upload_metadata
                iv_repository_id = ls_upload_repository-id
                iv_ref_name = ls_receive_command-ref_name
                iv_algorithm = 'sha1'
                iv_old_oid = ls_receive_command-old_oid ) = abap_false.
              ls_receive_result-reason = 'stale info'.
              lv_receive_ok = abap_false.
            ELSEIF ls_receive_command-new_oid =
                '0000000000000000000000000000000000000000'.
              IF ls_receive_current-oid IS INITIAL.
                ls_receive_result-reason = 'reference not found'.
                lv_receive_ok = abap_false.
              ELSE.
                DATA(lo_delete_transaction) = NEW zcl_hithub_local_unit_work( ).
                lo_delete_transaction->zif_hithub_transaction~start( ).
                lo_upload_metadata->zif_hithub_metadata_store~delete_reference(
                  iv_repository_id = ls_upload_repository-id
                  iv_name = ls_receive_command-ref_name
                  iv_expected_version = ls_receive_current-version ).
                lo_delete_transaction->zif_hithub_transaction~commit( ).
                ls_receive_result-ok = abap_true.
              ENDIF.
            ELSE.
              DATA(lo_receive_store) = NEW zcl_hithub_local_object_store( ).
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
                DATA(lo_existing_transaction) = NEW zcl_hithub_local_unit_work( ).
                lo_existing_transaction->zif_hithub_transaction~start( ).
                ls_receive_reference-repository_id = ls_upload_repository-id.
                ls_receive_reference-name = ls_receive_command-ref_name.
                ls_receive_reference-algorithm = 'sha1'.
                ls_receive_reference-oid = ls_receive_command-new_oid.
                lv_receive_version =
                  lo_upload_metadata->zif_hithub_metadata_store~save_reference(
                    is_reference = ls_receive_reference
                    iv_expected_version = ls_receive_current-version ).
                IF lv_receive_version IS INITIAL.
                  lo_existing_transaction->zif_hithub_transaction~rollback( ).
                  ls_receive_result-reason = 'ref update failed'.
                  lv_receive_ok = abap_false.
                ELSE.
                  lo_existing_transaction->zif_hithub_transaction~commit( ).
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
                  io_compression = lo_receive_compression
                  io_base_resolver = lo_receive_base ).
                DATA(lo_receive_transaction) = NEW zcl_hithub_local_unit_work( ).
                DATA(lo_receive_receiver) = NEW zcl_hithub_pack_receiver(
                  io_codec = lo_receive_codec io_store = lo_receive_store
                  io_metadata = lo_upload_metadata
                  io_transaction = lo_receive_transaction ).
                IF lo_receive_receiver->receive(
                    iv_pack = ls_receive_request-pack
                    iv_repository_id = ls_upload_repository-id
                    iv_ref_name = ls_receive_command-ref_name
                    iv_target_oid = ls_receive_command-new_oid
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
            it_results = lt_receive_results ).
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
        ls_upload_head = lo_upload_metadata->zif_hithub_metadata_store~read_reference(
          iv_repository_id = ls_upload_repository-id
          iv_name = lv_upload_head_ref ).
        IF ls_upload_head-oid IS NOT INITIAL.
          ls_upload_head-name = 'HEAD'.
          ls_upload_head-symbolic_target = lv_upload_head_ref.
          APPEND ls_upload_head TO lt_upload_references.
        ENDIF.
        lv_upload_body = zcl_hithub_v2_ls_refs=>build(
          iv_repository_id = ls_upload_repository-id
          it_references = lt_upload_references
          iv_symrefs = abap_true ).
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
            IF lo_upload_store->zif_hithub_object_store~contains(
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
          DATA(lo_legacy_store) = NEW zcl_hithub_local_object_store( ).
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
            IF lo_legacy_store->zif_hithub_object_store~contains(
                is_key = ls_legacy_key ) = abap_true.
              APPEND lv_legacy_oid TO lt_legacy_common.
            ENDIF.
          ENDLOOP.

          lv_legacy_negotiation = zcl_hithub_upload_negotiation=>build(
            is_request = ls_legacy_request
            it_common = lt_legacy_common ).
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
      DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).

      lv_repository_name = ls_route-repository_name.
      IF lv_repository_name IS NOT INITIAL.
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
        NEW zcl_hithub_local_meta_store( ) ).
      IF lv_path = '/api/repos' AND lv_rest_method = 'GET'.
        DATA(lt_rest_repositories) = lo_rest_query->list( ).
        server->response->set_status(
          code = 200 reason = 'OK' ).
        server->response->set_content_type( 'application/json' ).
        server->response->set_data(
          zcl_hithub_repo_representation=>list( lt_rest_repositories ) ).
      ELSEIF lv_rest_method = 'GET'.
        DATA lv_rest_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)$' IN lv_path
          SUBMATCHES lv_rest_repository_name.
        IF sy-subrc <> 0 OR lv_rest_repository_name IS INITIAL.
          DATA(ls_rest_query_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404
            iv_detail = 'Repository route was not found.'
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
              iv_status = 404
              iv_detail = 'Repository was not found.'
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
              zcl_hithub_repo_representation=>one( ls_rest_repository ) ).
          ENDIF.
        ENDIF.
      ELSEIF lv_rest_method = 'PATCH'.
        DATA lv_patch_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)$' IN lv_path
          SUBMATCHES lv_patch_repository_name.
        IF sy-subrc <> 0 OR lv_patch_repository_name IS INITIAL.
          DATA(ls_patch_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404
            iv_detail = 'Repository route was not found.'
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
              iv_status = 404
              iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_patch_problem-content_type ).
            server->response->set_data( ls_patch_problem-body ).
          ELSE.
            DATA(lo_patch_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method
              iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_patch_if_match TYPE string.
            DATA lv_patch_expected TYPE int8.
            lv_patch_if_match = lo_patch_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_patch_if_match WITH ''.
            IF lv_patch_if_match IS INITIAL
                OR lv_patch_if_match CN '0123456789'.
              ls_patch_problem = zcl_hithub_problem_response=>build(
                iv_status = 428
                iv_detail = 'If-Match must contain the current repository version.'
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
                  iv_status = 400
                  iv_detail = 'Patch body contains invalid or unsupported fields.'
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = 400 reason = 'Bad Request' ).
                server->response->set_content_type(
                  ls_patch_problem-content_type ).
                server->response->set_data( ls_patch_problem-body ).
              ELSE.
                DATA(lo_patch_update) = NEW zcl_hithub_repository_update(
                  io_metadata = NEW zcl_hithub_local_meta_store( )
                  io_transaction = NEW zcl_hithub_local_unit_work( ) ).
                DATA(ls_patch_result) = lo_patch_update->update(
                  iv_repository_id = ls_patch_repository-id
                  iv_description = lv_patch_description
                  iv_description_provided = lv_patch_description_seen
                  iv_default_branch = lv_patch_branch
                  iv_default_branch_provided = lv_patch_branch_seen
                  iv_expected_version = lv_patch_expected ).
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
                    iv_status = lv_patch_status
                    iv_detail = ls_patch_result-reason
                    iv_instance = lv_path ).
                  server->response->set_status(
                    code = lv_patch_status reason = 'Update Failed' ).
                  server->response->set_content_type(
                    ls_patch_problem-content_type ).
                  server->response->set_data( ls_patch_problem-body ).
                ELSE.
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
      ELSEIF lv_rest_method = 'DELETE'.
        DATA lv_delete_repository_name TYPE string.
        FIND REGEX '^/api/repos/([A-Za-z0-9._-]+)$' IN lv_path
          SUBMATCHES lv_delete_repository_name.
        IF sy-subrc <> 0 OR lv_delete_repository_name IS INITIAL.
          DATA(ls_delete_problem) = zcl_hithub_problem_response=>build(
            iv_status = 404
            iv_detail = 'Repository route was not found.'
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
              iv_status = 404
              iv_detail = 'Repository was not found.'
              iv_instance = lv_path ).
            server->response->set_status(
              code = 404 reason = 'Not Found' ).
            server->response->set_content_type(
              ls_delete_problem-content_type ).
            server->response->set_data( ls_delete_problem-body ).
          ELSE.
            DATA(lo_delete_context) = zcl_hithub_rest_context=>for_local(
              iv_method = lv_rest_method
              iv_path = lv_path
              iv_body = server->request->get_data( )
              iv_correlation_id = server->request->get_header_field(
                'X-Request-ID' )
              iv_idempotency_key = server->request->get_header_field(
                'Idempotency-Key' )
              iv_if_match = server->request->get_header_field( 'If-Match' ) ).
            DATA lv_delete_if_match TYPE string.
            DATA lv_delete_expected TYPE int8.
            lv_delete_if_match = lo_delete_context->if_match( ).
            REPLACE ALL OCCURRENCES OF '"' IN lv_delete_if_match WITH ''.
            IF lv_delete_if_match IS INITIAL
                OR lv_delete_if_match CN '0123456789'.
              ls_delete_problem = zcl_hithub_problem_response=>build(
                iv_status = 428
                iv_detail = 'If-Match must contain the current repository version.'
                iv_instance = lv_path ).
              server->response->set_status(
                code = 428 reason = 'Precondition Required' ).
              server->response->set_content_type(
                ls_delete_problem-content_type ).
              server->response->set_data( ls_delete_problem-body ).
            ELSE.
              lv_delete_expected = lv_delete_if_match.
              DATA(lo_delete_service) = NEW zcl_hithub_repository_deletion(
                io_metadata = NEW zcl_hithub_local_meta_store( )
                io_transaction = NEW zcl_hithub_local_unit_work( ) ).
              DATA(ls_delete_result) = lo_delete_service->delete(
                iv_repository_id = ls_delete_repository-id
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
                  iv_status = lv_delete_status
                  iv_detail = ls_delete_result-reason
                  iv_instance = lv_path ).
                server->response->set_status(
                  code = lv_delete_status reason = 'Deletion Failed' ).
                server->response->set_content_type(
                  ls_delete_problem-content_type ).
                server->response->set_data( ls_delete_problem-body ).
              ELSE.
                server->response->set_status(
                  code = 204 reason = 'No Content' ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSEIF lv_path = '/api/repos' AND lv_rest_method = 'POST'.
        DATA(lo_rest_context) = zcl_hithub_rest_context=>for_local(
          iv_method = lv_rest_method
          iv_path = lv_path
          iv_body = server->request->get_data( )
          iv_correlation_id = server->request->get_header_field(
            'X-Request-ID' )
          iv_idempotency_key = server->request->get_header_field(
            'Idempotency-Key' )
          iv_if_match = server->request->get_header_field( 'If-Match' ) ).
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
          DATA(lo_rest_metadata) = NEW zcl_hithub_local_meta_store( ).
          DATA(lo_rest_transaction) = NEW zcl_hithub_local_unit_work( ).
          DATA(lo_rest_identity) = NEW zcl_hithub_system_identity( ).
          DATA(lo_rest_creation) = NEW zcl_hithub_repository_creation(
            io_metadata = lo_rest_metadata
            io_transaction = lo_rest_transaction
            io_identity = lo_rest_identity ).
          DATA(ls_rest_result) = lo_rest_creation->create(
            iv_name = lv_rest_name
            iv_description = lv_rest_description
            iv_default_branch = lv_rest_default_branch ).
        ENDIF.
        IF lv_rest_body_valid = abap_false.
          DATA(ls_rest_problem) = zcl_hithub_problem_response=>build(
            iv_status = 400
            iv_detail = 'Request body must be a JSON object with a string name.'
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
            iv_status = lv_rest_status
            iv_detail = ls_rest_result-reason
            iv_instance = lv_path ).
          server->response->set_status(
            code = ls_rest_problem-status reason = 'Request Failed' ).
          server->response->set_content_type(
            ls_rest_problem-content_type ).
          server->response->set_data( ls_rest_problem-body ).
        ELSE.
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
            name = 'Location'
            value = |/api/repos/{ ls_rest_result-repository-name }| ).
          server->response->set_content_type( 'application/json' ).
          server->response->set_data(
            zcl_hithub_json=>serialize_data( lt_rest_members ) ).
        ENDIF.
      ELSE.
        DATA(ls_method_problem) = zcl_hithub_problem_response=>build(
          iv_status = 501
          iv_detail = 'This REST route is not implemented yet.'
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
