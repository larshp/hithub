CLASS zcl_hithub_pull_request_state DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_draft TYPE string VALUE 'draft'.
    CONSTANTS c_open TYPE string VALUE 'open'.
    CONSTANTS c_closed TYPE string VALUE 'closed'.
    CONSTANTS c_merged TYPE string VALUE 'merged'.

    CLASS-METHODS is_valid
      IMPORTING
        iv_state TYPE string
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    CLASS-METHODS can_transition
      IMPORTING
        iv_from TYPE string
        iv_to   TYPE string
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.
ENDCLASS.

CLASS zcl_hithub_pull_request_state IMPLEMENTATION.

  METHOD is_valid.
    rv_valid = boolc( iv_state = c_open
      OR iv_state = c_draft
      OR iv_state = c_closed
      OR iv_state = c_merged ).
  ENDMETHOD.

  METHOD can_transition.
    CLEAR rv_allowed.
    IF is_valid( iv_from ) = abap_false OR is_valid( iv_to ) = abap_false.
      RETURN.
    ENDIF.
    IF iv_from = iv_to.
      rv_allowed = abap_true.
      RETURN.
    ENDIF.

    CASE iv_from.
      WHEN c_draft.
        rv_allowed = boolc( iv_to = c_open OR iv_to = c_closed ).
      WHEN c_open.
        rv_allowed = boolc( iv_to = c_closed OR iv_to = c_merged ).
      WHEN c_closed.
        rv_allowed = boolc( iv_to = c_open ).
      WHEN c_merged.
        CLEAR rv_allowed.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
