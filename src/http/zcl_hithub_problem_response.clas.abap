CLASS zcl_hithub_problem_response DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_response.
    TYPES   status TYPE i.
    TYPES   content_type TYPE string.
    TYPES   body TYPE xstring.
    TYPES END OF ty_response.

    CLASS-METHODS build
      IMPORTING
        iv_status TYPE i
        iv_detail TYPE string OPTIONAL
        iv_type TYPE string OPTIONAL
        iv_title TYPE string OPTIONAL
        iv_instance TYPE string OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE ty_response.

  PRIVATE SECTION.
    CLASS-METHODS title_for_status
      IMPORTING
        iv_status TYPE i
      RETURNING
        VALUE(rv_title) TYPE string.
ENDCLASS.

CLASS zcl_hithub_problem_response IMPLEMENTATION.

  METHOD build.
    DATA lt_members TYPE zcl_hithub_json=>ty_members.
    DATA ls_member TYPE zcl_hithub_json=>ty_member.
    DATA lv_title TYPE string.
    DATA lv_type TYPE string.
    DATA lv_status TYPE string.

    rs_response-status = iv_status.
    rs_response-content_type = 'application/problem+json'.
    lv_title = iv_title.
    IF lv_title IS INITIAL.
      lv_title = title_for_status( iv_status ).
    ENDIF.
    lv_type = iv_type.
    IF lv_type IS INITIAL.
      lv_type = 'about:blank'.
    ENDIF.
    ls_member-name = 'type'.
    ls_member-kind = 'string'.
    ls_member-value = lv_type.
    APPEND ls_member TO lt_members.
    CLEAR ls_member.
    ls_member-name = 'title'.
    ls_member-kind = 'string'.
    ls_member-value = lv_title.
    APPEND ls_member TO lt_members.
    CLEAR ls_member.
    ls_member-name = 'status'.
    ls_member-kind = 'number'.
    lv_status = |{ iv_status }|.
    ls_member-value = lv_status.
    APPEND ls_member TO lt_members.
    IF iv_detail IS NOT INITIAL.
      CLEAR ls_member.
      ls_member-name = 'detail'.
      ls_member-kind = 'string'.
      ls_member-value = iv_detail.
      APPEND ls_member TO lt_members.
    ENDIF.
    IF iv_instance IS NOT INITIAL.
      CLEAR ls_member.
      ls_member-name = 'instance'.
      ls_member-kind = 'string'.
      ls_member-value = iv_instance.
      APPEND ls_member TO lt_members.
    ENDIF.
    rs_response-body = zcl_hithub_json=>serialize_data( lt_members ).
  ENDMETHOD.

  METHOD title_for_status.
    CASE iv_status.
      WHEN 400.
        rv_title = 'Bad Request'.
      WHEN 401.
        rv_title = 'Unauthorized'.
      WHEN 403.
        rv_title = 'Forbidden'.
      WHEN 404.
        rv_title = 'Not Found'.
      WHEN 405.
        rv_title = 'Method Not Allowed'.
      WHEN 409.
        rv_title = 'Conflict'.
      WHEN 412.
        rv_title = 'Precondition Failed'.
      WHEN 415.
        rv_title = 'Unsupported Media Type'.
      WHEN 422.
        rv_title = 'Unprocessable Content'.
      WHEN 428.
        rv_title = 'Precondition Required'.
      WHEN 429.
        rv_title = 'Too Many Requests'.
      WHEN 500.
        rv_title = 'Internal Server Error'.
      WHEN 501.
        rv_title = 'Not Implemented'.
      WHEN OTHERS.
        rv_title = 'HTTP Error'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
