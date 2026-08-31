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
    ASSERT zcl_hithub_pull_request_state=>is_valid(
      zcl_hithub_pull_request_state=>c_draft ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>is_valid(
      zcl_hithub_pull_request_state=>c_open ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>is_valid(
      zcl_hithub_pull_request_state=>c_closed ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>is_valid(
      zcl_hithub_pull_request_state=>c_merged ) = abap_true.
  ENDMETHOD.

  METHOD draft_can_be_ready.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_draft
      iv_to   = zcl_hithub_pull_request_state=>c_open ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_draft
      iv_to   = zcl_hithub_pull_request_state=>c_merged ) = abap_false.
  ENDMETHOD.

  METHOD valid_transitions.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_open
      iv_to   = zcl_hithub_pull_request_state=>c_closed ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_open
      iv_to   = zcl_hithub_pull_request_state=>c_merged ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_closed
      iv_to   = zcl_hithub_pull_request_state=>c_open ) = abap_true.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_open
      iv_to   = zcl_hithub_pull_request_state=>c_open ) = abap_true.
  ENDMETHOD.

  METHOD merged_is_terminal.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_merged
      iv_to   = zcl_hithub_pull_request_state=>c_open ) = abap_false.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = zcl_hithub_pull_request_state=>c_merged
      iv_to   = zcl_hithub_pull_request_state=>c_closed ) = abap_false.
  ENDMETHOD.

  METHOD invalid_states_rejected.
    ASSERT zcl_hithub_pull_request_state=>is_valid( 'unknown' ) = abap_false.
    ASSERT zcl_hithub_pull_request_state=>can_transition(
      iv_from = 'unknown' iv_to = zcl_hithub_pull_request_state=>c_open )
      = abap_false.
  ENDMETHOD.

ENDCLASS.
