CLASS ltcl_hithub_problem_response DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_problem_document FOR TESTING RAISING cx_static_check.
    METHODS uses_explicit_title_and_type FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_hithub_problem_response IMPLEMENTATION.

  METHOD builds_problem_document.
    DATA(ls_response) = zcl_hithub_problem_response=>build(
      iv_status   = 422
      iv_detail   = 'The repository name is invalid.'
      iv_instance = '/api/repos' ).
    DATA(ls_document) = zcl_hithub_json=>parse_data( ls_response-body ).
    DATA ls_member TYPE zcl_hithub_json=>ty_member.

    ASSERT ls_response-status = 422.
    ASSERT ls_response-content_type = 'application/problem+json'.
    ASSERT ls_document-valid = abap_true.
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'type'.
    ASSERT ls_member-value = 'about:blank'.
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'title'.
    ASSERT ls_member-value = 'Unprocessable Content'.
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'status'.
    ASSERT ls_member-kind = 'number'.
    ASSERT ls_member-value = '422'.
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'detail'.
    ASSERT ls_member-value = 'The repository name is invalid.'.
  ENDMETHOD.

  METHOD uses_explicit_title_and_type.
    DATA(ls_response) = zcl_hithub_problem_response=>build(
      iv_status = 409
      iv_title  = 'Repository already exists'
      iv_type   = 'https://hithub.example/problems/repository-exists' ).
    DATA(ls_document) = zcl_hithub_json=>parse_data( ls_response-body ).
    DATA ls_member TYPE zcl_hithub_json=>ty_member.

    ASSERT ls_document-valid = abap_true.
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'title'.
    ASSERT ls_member-value = 'Repository already exists'.
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'type'.
    ASSERT ls_member-value =
      'https://hithub.example/problems/repository-exists'.
  ENDMETHOD.

ENDCLASS.
