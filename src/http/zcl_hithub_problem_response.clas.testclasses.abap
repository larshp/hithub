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

    cl_abap_unit_assert=>assert_equals( act = ls_response-status exp = 422 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_response-content_type
      exp = 'application/problem+json' ).
    cl_abap_unit_assert=>assert_true( act = ls_document-valid ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'type'.
    cl_abap_unit_assert=>assert_equals(
      act = ls_member-value
      exp = 'about:blank' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'title'.
    cl_abap_unit_assert=>assert_equals(
      act = ls_member-value
      exp = 'Unprocessable Content' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'status'.
    cl_abap_unit_assert=>assert_equals( act = ls_member-kind exp = 'number' ).
    cl_abap_unit_assert=>assert_equals( act = ls_member-value exp = '422' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'detail'.
    cl_abap_unit_assert=>assert_equals(
      act = ls_member-value
      exp = 'The repository name is invalid.' ).
  ENDMETHOD.

  METHOD uses_explicit_title_and_type.
    DATA(ls_response) = zcl_hithub_problem_response=>build(
      iv_status = 409
      iv_title  = 'Repository already exists'
      iv_type   = 'https://hithub.example/problems/repository-exists' ).
    DATA(ls_document) = zcl_hithub_json=>parse_data( ls_response-body ).
    DATA ls_member TYPE zcl_hithub_json=>ty_member.

    cl_abap_unit_assert=>assert_true( act = ls_document-valid ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'title'.
    cl_abap_unit_assert=>assert_equals(
      act = ls_member-value
      exp = 'Repository already exists' ).
    READ TABLE ls_document-members INTO ls_member WITH KEY name = 'type'.
    cl_abap_unit_assert=>assert_equals(
      act = ls_member-value
      exp = 'https://hithub.example/problems/repository-exists' ).
  ENDMETHOD.

ENDCLASS.
