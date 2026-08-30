CLASS zcl_hithub_issue_meta_api DEFINITION
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
      VALUE '^/api/repos/([A-Za-z0-9._-]+)/issues/([^/]+)/(labels|assignees)(?:/(.+))?$'.
    CONSTANTS c_labels TYPE string VALUE 'labels'.

    CLASS-METHODS collection
      IMPORTING
        iv_resource    TYPE string
        it_values      TYPE zcl_hithub_issue_labels=>ty_labels
      RETURNING
        VALUE(rv_body) TYPE xstring.

    CLASS-METHODS single
      IMPORTING
        iv_resource    TYPE string
        iv_value       TYPE string
      RETURNING
        VALUE(rv_body) TYPE xstring.

    CLASS-METHODS member_name
      IMPORTING
        iv_resource    TYPE string
      RETURNING
        VALUE(rv_name) TYPE string.

    CLASS-METHODS parse_value
      IMPORTING
        iv_resource     TYPE string
        iv_body         TYPE xstring
      RETURNING
        VALUE(rv_value) TYPE string.
ENDCLASS.

CLASS zcl_hithub_issue_meta_api IMPLEMENTATION.

  METHOD matches.
    FIND REGEX c_route IN iv_path.
    rv_matches = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD handle.
    DATA lv_path TYPE string.
    DATA lv_method TYPE string.
    DATA lv_repository_name TYPE string.
    DATA lv_issue_id TYPE string.
    DATA lv_resource TYPE string.
    DATA lv_value TYPE string.
    DATA lv_action TYPE string.
    DATA lo_sink TYPE REF TO zif_hithub_event_sink.
    DATA lo_query TYPE REF TO zcl_hithub_repository_query.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_issue TYPE zcl_hithub_issues=>ty_issue.
    DATA lt_values TYPE zcl_hithub_issue_labels=>ty_labels.
    DATA lv_changed TYPE abap_bool.

    lv_path = io_context->path( ).
    lv_method = io_context->request_method( ).
    FIND REGEX c_route IN lv_path
      SUBMATCHES lv_repository_name lv_issue_id lv_resource lv_value.
    IF sy-subrc <> 0.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Issue metadata route was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    lo_query = NEW zcl_hithub_repository_query(
      NEW zcl_hithub_local_meta_store( ) ).
    ls_repository = lo_query->find( lv_repository_name ).
    IF ls_repository-id IS INITIAL.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Repository was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.
    ls_issue = zcl_hithub_issues=>read(
      iv_repository_id = ls_repository-id iv_id = lv_issue_id ).
    IF ls_issue-id IS INITIAL.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Issue was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    IF lv_method = 'GET'.
      IF lv_value IS NOT INITIAL.
        rs_response = zcl_hithub_rest_response=>problem(
          iv_status   = 404
          iv_detail   = 'Issue metadata route was not found.'
          iv_instance = lv_path ).
        RETURN.
      ENDIF.
      IF lv_resource = c_labels.
        lt_values = zcl_hithub_issue_labels=>list(
          iv_repository_id = ls_repository-id iv_issue_id = lv_issue_id ).
      ELSE.
        lt_values = zcl_hithub_issue_assignees=>list(
          iv_repository_id = ls_repository-id iv_issue_id = lv_issue_id ).
      ENDIF.
      rs_response = zcl_hithub_rest_response=>json(
        iv_status = 200
        iv_body   = collection(
          iv_resource = lv_resource it_values = lt_values ) ).
      RETURN.
    ENDIF.

    lo_sink = io_sink.
    IF lo_sink IS INITIAL.
      lo_sink = NEW zcl_hithub_local_event_sink( ).
    ENDIF.

    IF lv_method = 'POST'.
      IF lv_value IS NOT INITIAL.
        rs_response = zcl_hithub_rest_response=>problem(
          iv_status   = 404
          iv_detail   = 'Issue metadata route was not found.'
          iv_instance = lv_path ).
        RETURN.
      ENDIF.
      lv_value = parse_value(
        iv_resource = lv_resource iv_body = io_context->body( ) ).
      IF lv_value IS INITIAL.
        rs_response = zcl_hithub_rest_response=>problem(
          iv_status   = 400
          iv_detail   = |Body must contain a non-empty string { lv_resource } entry.|
          iv_instance = lv_path ).
        RETURN.
      ENDIF.
      IF lv_resource = c_labels.
        lv_changed = zcl_hithub_issue_labels=>add(
          iv_repository_id = ls_repository-id
          iv_issue_id      = lv_issue_id
          iv_label         = lv_value ).
        lv_action = 'issue.label'.
      ELSE.
        lv_changed = zcl_hithub_issue_assignees=>add(
          iv_repository_id = ls_repository-id
          iv_issue_id      = lv_issue_id
          iv_actor         = lv_value ).
        lv_action = 'issue.assign'.
      ENDIF.
      IF lv_changed = abap_false.
        rs_response = zcl_hithub_rest_response=>problem(
          iv_status   = 409
          iv_detail   = 'The entry is already present or was rejected.'
          iv_instance = lv_path ).
        RETURN.
      ENDIF.
      zcl_hithub_audit_log=>record(
        io_sink         = lo_sink
        io_context      = io_context
        iv_action       = lv_action
        iv_subject_type = 'issue'
        iv_subject_id   = lv_issue_id
        iv_details      = |repository={ ls_repository-id } value={ lv_value }| ).
      rs_response = zcl_hithub_rest_response=>json(
        iv_status   = 201
        iv_body     = single( iv_resource = lv_resource iv_value = lv_value )
        iv_location = |{ lv_path }/{ lv_value }| ).
      RETURN.
    ENDIF.

    IF lv_method <> 'DELETE'.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 405
        iv_detail   = 'Only GET, POST and DELETE are supported for this route.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.
    IF lv_value IS INITIAL.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'The entry to remove must be part of the path.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.
    IF lv_resource = c_labels.
      lv_changed = zcl_hithub_issue_labels=>remove(
        iv_repository_id = ls_repository-id
        iv_issue_id      = lv_issue_id
        iv_label         = lv_value ).
      lv_action = 'issue.unlabel'.
    ELSE.
      lv_changed = zcl_hithub_issue_assignees=>remove(
        iv_repository_id = ls_repository-id
        iv_issue_id      = lv_issue_id
        iv_actor         = lv_value ).
      lv_action = 'issue.unassign'.
    ENDIF.
    IF lv_changed = abap_false.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'The entry was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.
    zcl_hithub_audit_log=>record(
      io_sink         = lo_sink
      io_context      = io_context
      iv_action       = lv_action
      iv_subject_type = 'issue'
      iv_subject_id   = lv_issue_id
      iv_details      = |repository={ ls_repository-id } value={ lv_value }| ).
    rs_response = zcl_hithub_rest_response=>empty( 204 ).
  ENDMETHOD.

  METHOD collection.
    DATA lv_value TYPE string.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_json TYPE string.

    lv_json = '['.
    LOOP AT it_values INTO lv_value.
      CLEAR lt_members.
      APPEND VALUE #( name = member_name( iv_resource ) kind = 'string'
        value = lv_value ) TO lt_members.
      IF lv_json <> '['.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize( lt_members ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

  METHOD single.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.

    APPEND VALUE #( name = member_name( iv_resource ) kind = 'string'
      value = iv_value ) TO lt_members.
    rv_body = zcl_hithub_json=>serialize_data( lt_members ).
  ENDMETHOD.

  METHOD member_name.
    IF iv_resource = c_labels.
      rv_name = 'label'.
    ELSE.
      rv_name = 'actor'.
    ENDIF.
  ENDMETHOD.

  METHOD parse_value.
    DATA ls_document TYPE zcl_hithub_json=>ty_document.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_name TYPE string.

    CLEAR rv_value.
    lv_name = member_name( iv_resource ).
    ls_document = zcl_hithub_json=>parse_data( iv_body ).
    IF ls_document-valid = abap_false
        OR lines( ls_document-members ) <> 1.
      RETURN.
    ENDIF.
    READ TABLE ls_document-members INDEX 1 INTO ls_member.
    IF ls_member-name <> lv_name OR ls_member-kind <> 'string'.
      RETURN.
    ENDIF.
    rv_value = ls_member-value.
  ENDMETHOD.

ENDCLASS.
