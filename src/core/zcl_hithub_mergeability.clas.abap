CLASS zcl_hithub_mergeability DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_clean TYPE string VALUE 'clean'.
    CONSTANTS c_conflicting TYPE string VALUE 'conflicting'.
    CONSTANTS c_stale TYPE string VALUE 'stale'.
    CONSTANTS c_blocked TYPE string VALUE 'blocked'.
    CONSTANTS c_unknown TYPE string VALUE 'unknown'.

    CLASS-METHODS evaluate
      IMPORTING
        iv_head_oid          TYPE string
        iv_expected_head_oid TYPE string
        iv_base_oid          TYPE string
        iv_expected_base_oid TYPE string
        iv_merge_clean      TYPE abap_bool
        iv_blocked          TYPE abap_bool
      RETURNING
        VALUE(rv_state) TYPE string.
ENDCLASS.

CLASS zcl_hithub_mergeability IMPLEMENTATION.

  METHOD evaluate.
    rv_state = c_unknown.
    IF iv_head_oid IS INITIAL OR iv_expected_head_oid IS INITIAL
        OR iv_base_oid IS INITIAL OR iv_expected_base_oid IS INITIAL.
      RETURN.
    ENDIF.
    IF iv_head_oid <> iv_expected_head_oid
        OR iv_base_oid <> iv_expected_base_oid.
      rv_state = c_stale.
      RETURN.
    ENDIF.
    IF iv_blocked = abap_true.
      rv_state = c_blocked.
      RETURN.
    ENDIF.
    IF iv_merge_clean = abap_false.
      rv_state = c_conflicting.
      RETURN.
    ENDIF.
    rv_state = c_clean.
  ENDMETHOD.

ENDCLASS.
