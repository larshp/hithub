CLASS zcl_hithub_pr_discussion_api DEFINITION
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
      VALUE '^/api/repos/([A-Za-z0-9._-]+)/pulls/([^/]+)/(reviews|comments)$'.

    CLASS-METHODS reviews
      IMPORTING
        iv_repository_id   TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rv_body)     TYPE xstring.

    CLASS-METHODS comments
      IMPORTING
        iv_repository_id   TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rv_body)     TYPE xstring.

    CLASS-METHODS create_review
      IMPORTING
        io_context         TYPE REF TO zif_hithub_rest_context
        io_sink            TYPE REF TO zif_hithub_event_sink
        iv_repository_id   TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rs_response) TYPE zcl_hithub_rest_response=>ty_response
      RAISING
        cx_static_check.

    CLASS-METHODS create_comment
      IMPORTING
        io_context         TYPE REF TO zif_hithub_rest_context
        io_sink            TYPE REF TO zif_hithub_event_sink
        iv_repository_id   TYPE string
        iv_pull_request_id TYPE string
      RETURNING
        VALUE(rs_response) TYPE zcl_hithub_rest_response=>ty_response
      RAISING
        cx_static_check.
ENDCLASS.

CLASS zcl_hithub_pr_discussion_api IMPLEMENTATION.

  METHOD matches.
    FIND REGEX c_route IN iv_path.
    rv_matches = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD handle.
    DATA lv_path TYPE string.
    DATA lv_method TYPE string.
    DATA lv_repository_name TYPE string.
    DATA lv_pull_request_id TYPE string.
    DATA lv_resource TYPE string.
    DATA lo_sink TYPE REF TO zif_hithub_event_sink.
    DATA lo_query TYPE REF TO zcl_hithub_repository_query.
    DATA ls_repository TYPE zif_hithub_metadata_store=>ty_repository.
    DATA ls_pull_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.

    lv_path = io_context->path( ).
    lv_method = io_context->request_method( ).
    FIND REGEX c_route IN lv_path
      SUBMATCHES lv_repository_name lv_pull_request_id lv_resource.
    IF sy-subrc <> 0.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Pull-request discussion route was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    lo_query = NEW zcl_hithub_repository_query(
      zcl_hithub_persistence=>metadata_store( ) ).
    ls_repository = lo_query->find( lv_repository_name ).
    IF ls_repository-id IS INITIAL.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Repository was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.
    ls_pull_request = zcl_hithub_pull_requests=>find(
      iv_repository_id = ls_repository-id iv_id = lv_pull_request_id ).
    IF ls_pull_request-id IS INITIAL.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 404
        iv_detail   = 'Pull request was not found.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    IF lv_method = 'GET'.
      IF lv_resource = 'reviews'.
        rs_response = zcl_hithub_rest_response=>json(
          iv_status = 200
          iv_body   = reviews(
            iv_repository_id   = ls_repository-id
            iv_pull_request_id = lv_pull_request_id ) ).
      ELSE.
        rs_response = zcl_hithub_rest_response=>json(
          iv_status = 200
          iv_body   = comments(
            iv_repository_id   = ls_repository-id
            iv_pull_request_id = lv_pull_request_id ) ).
      ENDIF.
      RETURN.
    ENDIF.
    IF lv_method <> 'POST'.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 405
        iv_detail   = 'Only GET and POST are supported for this route.'
        iv_instance = lv_path ).
      RETURN.
    ENDIF.

    lo_sink = io_sink.
    IF lo_sink IS INITIAL.
      lo_sink = zcl_hithub_persistence=>event_sink( ).
    ENDIF.
    IF lv_resource = 'reviews'.
      rs_response = create_review(
        io_context         = io_context
        io_sink            = lo_sink
        iv_repository_id   = ls_repository-id
        iv_pull_request_id = lv_pull_request_id ).
    ELSE.
      rs_response = create_comment(
        io_context         = io_context
        io_sink            = lo_sink
        iv_repository_id   = ls_repository-id
        iv_pull_request_id = lv_pull_request_id ).
    ENDIF.
  ENDMETHOD.

  METHOD reviews.
    DATA lt_reviews TYPE zcl_hithub_pr_reviews=>ty_reviews.
    DATA ls_review TYPE zcl_hithub_pr_reviews=>ty_review.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_json TYPE string.

    lt_reviews = zcl_hithub_pr_reviews=>list(
      iv_repository_id   = iv_repository_id
      iv_pull_request_id = iv_pull_request_id ).
    lv_json = '['.
    LOOP AT lt_reviews INTO ls_review.
      CLEAR lt_members.
      APPEND VALUE #( name = 'id' kind = 'string'
        value = ls_review-review_id ) TO lt_members.
      APPEND VALUE #( name = 'actor' kind = 'string'
        value = ls_review-actor ) TO lt_members.
      APPEND VALUE #( name = 'state' kind = 'string'
        value = ls_review-state ) TO lt_members.
      APPEND VALUE #( name = 'body' kind = 'string'
        value = ls_review-body ) TO lt_members.
      APPEND VALUE #( name = 'created_at' kind = 'string'
        value = ls_review-created_at ) TO lt_members.
      IF lv_json <> '['.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize( lt_members ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

  METHOD comments.
    DATA lt_comments TYPE zcl_hithub_pr_comments=>ty_comments.
    DATA ls_comment TYPE zcl_hithub_pr_comments=>ty_comment.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_json TYPE string.

    lt_comments = zcl_hithub_pr_comments=>list(
      iv_repository_id   = iv_repository_id
      iv_pull_request_id = iv_pull_request_id ).
    lv_json = '['.
    LOOP AT lt_comments INTO ls_comment.
      CLEAR lt_members.
      APPEND VALUE #( name = 'id' kind = 'string'
        value = ls_comment-comment_id ) TO lt_members.
      APPEND VALUE #( name = 'actor' kind = 'string'
        value = ls_comment-actor ) TO lt_members.
      APPEND VALUE #( name = 'body' kind = 'string'
        value = ls_comment-body ) TO lt_members.
      APPEND VALUE #( name = 'created_at' kind = 'string'
        value = ls_comment-created_at ) TO lt_members.
      IF lv_json <> '['.
        lv_json = lv_json && ','.
      ENDIF.
      lv_json = lv_json && zcl_hithub_json=>serialize( lt_members ).
    ENDLOOP.
    lv_json = lv_json && ']'.
    rv_body = cl_abap_codepage=>convert_to( lv_json ).
  ENDMETHOD.

  METHOD create_review.
    DATA ls_document TYPE zcl_hithub_json=>ty_document.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA ls_review TYPE zcl_hithub_pr_reviews=>ty_review.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_valid TYPE abap_bool.
    DATA lv_id_seen TYPE abap_bool.
    DATA lv_state_seen TYPE abap_bool.

    ls_document = zcl_hithub_json=>parse_data( io_context->body( ) ).
    lv_valid = ls_document-valid.
    ls_review-repository_id = iv_repository_id.
    ls_review-pull_request_id = iv_pull_request_id.
    ls_review-actor = io_context->actor_label( ).
    GET TIME STAMP FIELD ls_review-created_at.
    LOOP AT ls_document-members INTO ls_member.
      IF ls_member-kind <> 'string'.
        lv_valid = abap_false.
        CONTINUE.
      ENDIF.
      CASE ls_member-name.
        WHEN 'id'.
          ls_review-review_id = ls_member-value.
          lv_id_seen = abap_true.
        WHEN 'state'.
          ls_review-state = ls_member-value.
          lv_state_seen = abap_true.
        WHEN 'body'.
          ls_review-body = ls_member-value.
        WHEN OTHERS.
          lv_valid = abap_false.
      ENDCASE.
    ENDLOOP.
    IF lv_id_seen = abap_false OR lv_state_seen = abap_false
        OR zcl_hithub_pr_reviews=>is_valid_state( ls_review-state ) = abap_false.
      lv_valid = abap_false.
    ENDIF.
    IF lv_valid = abap_false.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 400
        iv_detail   = 'Review body must contain id and a valid state.'
        iv_instance = io_context->path( ) ).
      RETURN.
    ENDIF.
    IF zcl_hithub_pr_reviews=>add( ls_review ) = abap_false.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 409
        iv_detail   = 'Review already exists.'
        iv_instance = io_context->path( ) ).
      RETURN.
    ENDIF.
    zcl_hithub_audit_log=>record(
      io_sink         = io_sink
      io_context      = io_context
      iv_action       = 'pull_request.review'
      iv_subject_type = 'pull_request'
      iv_subject_id   = iv_pull_request_id
      iv_details      = |repository={ iv_repository_id } state={ ls_review-state }| ).
    APPEND VALUE #( name = 'id' kind = 'string'
      value = ls_review-review_id ) TO lt_members.
    APPEND VALUE #( name = 'actor' kind = 'string'
      value = ls_review-actor ) TO lt_members.
    APPEND VALUE #( name = 'state' kind = 'string'
      value = ls_review-state ) TO lt_members.
    APPEND VALUE #( name = 'body' kind = 'string'
      value = ls_review-body ) TO lt_members.
    APPEND VALUE #( name = 'created_at' kind = 'string'
      value = ls_review-created_at ) TO lt_members.
    rs_response = zcl_hithub_rest_response=>json(
      iv_status   = 201
      iv_body     = zcl_hithub_json=>serialize_data( lt_members )
      iv_location = |{ io_context->path( ) }/{ ls_review-review_id }| ).
  ENDMETHOD.

  METHOD create_comment.
    DATA ls_document TYPE zcl_hithub_json=>ty_document.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA ls_comment TYPE zcl_hithub_pr_comments=>ty_comment.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA lv_valid TYPE abap_bool.
    DATA lv_id_seen TYPE abap_bool.
    DATA lv_body_seen TYPE abap_bool.

    ls_document = zcl_hithub_json=>parse_data( io_context->body( ) ).
    lv_valid = ls_document-valid.
    ls_comment-repository_id = iv_repository_id.
    ls_comment-pull_request_id = iv_pull_request_id.
    ls_comment-actor = io_context->actor_label( ).
    GET TIME STAMP FIELD ls_comment-created_at.
    LOOP AT ls_document-members INTO ls_member.
      IF ls_member-kind <> 'string'.
        lv_valid = abap_false.
        CONTINUE.
      ENDIF.
      CASE ls_member-name.
        WHEN 'id'.
          ls_comment-comment_id = ls_member-value.
          lv_id_seen = abap_true.
        WHEN 'body'.
          ls_comment-body = ls_member-value.
          lv_body_seen = abap_true.
        WHEN OTHERS.
          lv_valid = abap_false.
      ENDCASE.
    ENDLOOP.
    IF lv_id_seen = abap_false OR lv_body_seen = abap_false.
      lv_valid = abap_false.
    ENDIF.
    IF lv_valid = abap_false.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 400
        iv_detail   = 'Comment body must contain string id and body.'
        iv_instance = io_context->path( ) ).
      RETURN.
    ENDIF.
    IF zcl_hithub_pr_comments=>add( ls_comment ) = abap_false.
      rs_response = zcl_hithub_rest_response=>problem(
        iv_status   = 409
        iv_detail   = 'Comment already exists.'
        iv_instance = io_context->path( ) ).
      RETURN.
    ENDIF.
    zcl_hithub_audit_log=>record(
      io_sink         = io_sink
      io_context      = io_context
      iv_action       = 'pull_request.comment'
      iv_subject_type = 'pull_request'
      iv_subject_id   = iv_pull_request_id
      iv_details      = |repository={ iv_repository_id }| ).
    APPEND VALUE #( name = 'id' kind = 'string'
      value = ls_comment-comment_id ) TO lt_members.
    APPEND VALUE #( name = 'actor' kind = 'string'
      value = ls_comment-actor ) TO lt_members.
    APPEND VALUE #( name = 'body' kind = 'string'
      value = ls_comment-body ) TO lt_members.
    APPEND VALUE #( name = 'created_at' kind = 'string'
      value = ls_comment-created_at ) TO lt_members.
    rs_response = zcl_hithub_rest_response=>json(
      iv_status   = 201
      iv_body     = zcl_hithub_json=>serialize_data( lt_members )
      iv_location = |{ io_context->path( ) }/{ ls_comment-comment_id }| ).
  ENDMETHOD.

ENDCLASS.
