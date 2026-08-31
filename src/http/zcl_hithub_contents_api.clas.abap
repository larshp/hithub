CLASS zcl_hithub_contents_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS matches
      IMPORTING
        iv_path           TYPE string
      RETURNING
        VALUE(rv_matches) TYPE abap_bool.

    CLASS-METHODS handle
      IMPORTING
        io_context         TYPE REF TO zif_hithub_rest_context
        io_sink            TYPE REF TO zif_hithub_event_sink OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE zcl_hithub_rest_response=>ty_response
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    CONSTANTS c_route TYPE string
      VALUE '^/api/repos/([A-Za-z0-9._-]+)/contents/(.+)$'.

    TYPES:
      BEGIN OF ty_request,
        valid             TYPE abap_bool,
        ref               TYPE string,
        content           TYPE string,
        message           TYPE string,
        expected_head_oid TYPE string,
      END OF ty_request.

    CLASS-METHODS parse
      IMPORTING
        iv_body           TYPE xstring
      RETURNING
        VALUE(rs_request) TYPE ty_request.

    CLASS-METHODS status_for
      IMPORTING
        is_result        TYPE zcl_hithub_file_editor=>ty_result
      RETURNING
        VALUE(rv_status) TYPE i.
ENDCLASS.

CLASS zcl_hithub_contents_api IMPLEMENTATION.

  METHOD matches.
    FIND REGEX c_route IN iv_path.
    rv_matches = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD parse.
    DATA ls_document TYPE zcl_hithub_json=>ty_document.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_content_seen TYPE abap_bool.

    CLEAR rs_request.
    ls_document = zcl_hithub_json=>parse_data( iv_body ).
    rs_request-valid = ls_document-valid.
    LOOP AT ls_document-members INTO ls_member.
      IF ls_member-kind <> 'string'.
        rs_request-valid = abap_false.
        CONTINUE.
      ENDIF.
      CASE ls_member-name.
        WHEN 'ref'.
          rs_request-ref = ls_member-value.
        WHEN 'content'.
          rs_request-content = ls_member-value.
          lv_content_seen = abap_true.
        WHEN 'message'.
          rs_request-message = ls_member-value.
        WHEN 'expected_head_oid'.
          rs_request-expected_head_oid = ls_member-value.
        WHEN OTHERS.
          rs_request-valid = abap_false.
      ENDCASE.
    ENDLOOP.
    IF lv_content_seen = abap_false OR rs_request-ref IS INITIAL
        OR rs_request-message IS INITIAL.
      rs_request-valid = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD status_for.
    IF is_result-stale = abap_true.
      rv_status = 409.
    ELSEIF is_result-reason CS 'was not found'.
      rv_status = 404.
    ELSE.
      rv_status = 422.
    ENDIF.
  ENDMETHOD.

  METHOD handle.
    DATA lv_path TYPE string.
    DATA lv_repository_name TYPE string.
    DATA lv_file_path TYPE string.
    DATA lo_sink TYPE REF TO zif_hithub_event_sink.
    DATA lo_query TYPE REF TO zcl_hithub_repository_query.
    DATA lo_metadata TYPE REF TO zcl_hithub_local_meta_store.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_request TYPE ty_request.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_status TYPE i.

    lv_path = io_context->path( ).
    IF io_context->request_method( ) <> 'PUT'.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 405
        iv_detail   = 'Only PUT writes file contents.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.
    FIND REGEX c_route IN lv_path
      SUBMATCHES lv_repository_name lv_file_path.
    IF sy-subrc <> 0.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Contents route was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    lo_metadata = NEW zcl_hithub_local_meta_store( ).
    lo_query = NEW zcl_hithub_repository_query( lo_metadata ).
    ls_repository = lo_query->find( lv_repository_name ).
    IF ls_repository-id IS INITIAL.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Repository was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    ls_request = parse( io_context->body( ) ).
    IF ls_request-valid = abap_false.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 400
        iv_detail   = 'Body must contain string ref, content, and message.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    lo_sink = io_sink.
    IF lo_sink IS INITIAL.
      lo_sink = NEW zcl_hithub_local_event_sink( ).
    ENDIF.
    DATA(lo_editor) = NEW zcl_hithub_file_editor(
      io_metadata    = lo_metadata
      io_objects     = NEW zcl_hithub_local_object_store( )
      io_transaction = NEW zcl_hithub_local_unit_work( )
      io_lock        = NEW zcl_hithub_local_repo_lock( ) ).
    DATA(ls_result) = lo_editor->save(
      iv_repository_id     = ls_repository-id
      iv_ref               = ls_request-ref
      iv_path              = lv_file_path
      iv_content           = ls_request-content
      iv_message           = ls_request-message
      iv_author            = zcl_hithub_commit_signature=>build(
        io_context->actor_label( ) )
      iv_expected_head_oid = ls_request-expected_head_oid
      iv_owner             = io_context->actor_label( ) ).
    IF ls_result-success = abap_false.
      lv_status = status_for( ls_result ).
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = lv_status
        iv_detail   = ls_result-reason
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    zcl_hithub_audit_log=>record(
      io_sink         = lo_sink
      io_context      = io_context
      iv_action       = 'contents.update'
      iv_subject_type = 'repository'
      iv_subject_id   = ls_repository-id
      iv_details      = |ref={ ls_result-ref } path={ lv_file_path } | &&
                        |commit={ ls_result-commit_oid }| ).
    APPEND VALUE #( name = 'ref' kind = 'string'
      value = ls_result-ref ) TO lt_members.
    APPEND VALUE #( name = 'path' kind = 'string'
      value = lv_file_path ) TO lt_members.
    APPEND VALUE #( name = 'commit_oid' kind = 'string'
      value = ls_result-commit_oid ) TO lt_members.
    APPEND VALUE #( name = 'tree_oid' kind = 'string'
      value = ls_result-tree_oid ) TO lt_members.
    APPEND VALUE #( name = 'blob_oid' kind = 'string'
      value = ls_result-blob_oid ) TO lt_members.
    rs_response = zcl_hithub_rest_response=>json(
      iv_status = 200
      iv_body   = zcl_hithub_json=>serialize_data( lt_members ) ).
  ENDMETHOD.

ENDCLASS.
