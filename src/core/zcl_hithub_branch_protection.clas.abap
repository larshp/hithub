CLASS zcl_hithub_branch_protection DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_rule,
        pattern          TYPE string,
        required_reviews TYPE i,
        allow_force_push TYPE abap_bool,
        allow_delete     TYPE abap_bool,
      END OF ty_rule,
      ty_rules TYPE STANDARD TABLE OF ty_rule WITH DEFAULT KEY.

    CLASS-METHODS allows
      IMPORTING
        it_rules            TYPE ty_rules
        iv_ref_name         TYPE string
        iv_is_delete        TYPE abap_bool
        iv_is_force_push    TYPE abap_bool
        iv_approved_reviews TYPE i
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.

ENDCLASS.

CLASS zcl_hithub_branch_protection IMPLEMENTATION.

  METHOD allows.
    DATA ls_rule TYPE ty_rule.
    DATA lv_required_reviews TYPE i.

    CLEAR rv_allowed.
    IF zcl_hithub_ref_validator=>is_valid( iv_ref_name ) = abap_false
        OR iv_approved_reviews < 0.
      RETURN.
    ENDIF.

    rv_allowed = abap_true.
    LOOP AT it_rules INTO ls_rule.
      CHECK ls_rule-pattern IS NOT INITIAL.
      CHECK iv_ref_name CP ls_rule-pattern.

      IF ls_rule-required_reviews < 0.
        CLEAR rv_allowed.
        RETURN.
      ENDIF.
      IF ls_rule-required_reviews > lv_required_reviews.
        lv_required_reviews = ls_rule-required_reviews.
      ENDIF.
      IF iv_is_delete = abap_true AND ls_rule-allow_delete = abap_false.
        CLEAR rv_allowed.
        RETURN.
      ENDIF.
      IF iv_is_force_push = abap_true
          AND ls_rule-allow_force_push = abap_false.
        CLEAR rv_allowed.
        RETURN.
      ENDIF.
    ENDLOOP.

    IF iv_approved_reviews < lv_required_reviews.
      CLEAR rv_allowed.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
