CLASS ltcl_pull_request_state DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS valid_states FOR TESTING RAISING cx_static_check.
    METHODS valid_transitions FOR TESTING RAISING cx_static_check.
    METHODS merged_is_terminal FOR TESTING RAISING cx_static_check.
    METHODS draft_can_be_ready FOR TESTING RAISING cx_static_check.
    METHODS invalid_states_rejected FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pull_request_state IMPLEMENTATION.

  METHOD valid_states.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>is_valid(
        zcl_hithub_pull_request_state=>c_draft ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>is_valid(
        zcl_hithub_pull_request_state=>c_open ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>is_valid(
        zcl_hithub_pull_request_state=>c_closed ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>is_valid(
        zcl_hithub_pull_request_state=>c_merged ) ).
  ENDMETHOD.

  METHOD draft_can_be_ready.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_draft
        iv_to   = zcl_hithub_pull_request_state=>c_open ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_draft
        iv_to   = zcl_hithub_pull_request_state=>c_merged ) ).
  ENDMETHOD.

  METHOD valid_transitions.
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_open
        iv_to   = zcl_hithub_pull_request_state=>c_closed ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_open
        iv_to   = zcl_hithub_pull_request_state=>c_merged ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_closed
        iv_to   = zcl_hithub_pull_request_state=>c_open ) ).
    cl_abap_unit_assert=>assert_true(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_open
        iv_to   = zcl_hithub_pull_request_state=>c_open ) ).
  ENDMETHOD.

  METHOD merged_is_terminal.
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_merged
        iv_to   = zcl_hithub_pull_request_state=>c_open ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = zcl_hithub_pull_request_state=>c_merged
        iv_to   = zcl_hithub_pull_request_state=>c_closed ) ).
  ENDMETHOD.

  METHOD invalid_states_rejected.
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pull_request_state=>is_valid( 'unknown' ) ).
    cl_abap_unit_assert=>assert_false(
      act = zcl_hithub_pull_request_state=>can_transition(
        iv_from = 'unknown' iv_to = zcl_hithub_pull_request_state=>c_open ) ).
  ENDMETHOD.

ENDCLASS.
