CLASS zcl_hithub_rest_response DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_response.
    TYPES   status       TYPE i.
    TYPES   reason       TYPE string.
    TYPES   content_type TYPE string.
    TYPES   location     TYPE string.
    TYPES   body         TYPE xstring.
    TYPES END OF ty_response.

    CLASS-METHODS json
      IMPORTING
        iv_status          TYPE i
        iv_body            TYPE xstring
        iv_location        TYPE string OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE ty_response.

    CLASS-METHODS empty
      IMPORTING
        iv_status          TYPE i
      RETURNING
        VALUE(rs_response) TYPE ty_response.

    CLASS-METHODS problem
      IMPORTING
        iv_status          TYPE i
        iv_detail          TYPE string
        iv_instance        TYPE string
      RETURNING
        VALUE(rs_response) TYPE ty_response.

    CLASS-METHODS reason_for_status
      IMPORTING
        iv_status        TYPE i
      RETURNING
        VALUE(rv_reason) TYPE string.
ENDCLASS.

CLASS zcl_hithub_rest_response IMPLEMENTATION.

  METHOD json.
    rs_response-status = iv_status.
    rs_response-reason = reason_for_status( iv_status ).
    rs_response-content_type = 'application/json'.
    rs_response-location = iv_location.
    rs_response-body = iv_body.
  ENDMETHOD.

  METHOD empty.
    rs_response-status = iv_status.
    rs_response-reason = reason_for_status( iv_status ).
    rs_response-content_type = 'application/json'.
  ENDMETHOD.

  METHOD problem.
    DATA ls_problem TYPE zcl_hithub_problem_response=>ty_response.

    ls_problem = zcl_hithub_problem_response=>build(
      iv_status   = iv_status
      iv_detail   = iv_detail
      iv_instance = iv_instance ).
    rs_response-status = ls_problem-status.
    rs_response-reason = reason_for_status( iv_status ).
    rs_response-content_type = ls_problem-content_type.
    rs_response-body = ls_problem-body.
  ENDMETHOD.

  METHOD reason_for_status.
    CASE iv_status.
      WHEN 200.
        rv_reason = 'OK'.
      WHEN 201.
        rv_reason = 'Created'.
      WHEN 204.
        rv_reason = 'No Content'.
      WHEN 400.
        rv_reason = 'Bad Request'.
      WHEN 404.
        rv_reason = 'Not Found'.
      WHEN 405.
        rv_reason = 'Method Not Allowed'.
      WHEN 409.
        rv_reason = 'Conflict'.
      WHEN 422.
        rv_reason = 'Unprocessable Content'.
      WHEN OTHERS.
        rv_reason = 'HTTP Error'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
