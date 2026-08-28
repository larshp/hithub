CLASS zcl_hithub_merge_base DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_commit,
        oid    TYPE string,
        parent TYPE string,
        parent2 TYPE string,
      END OF ty_commit,
      ty_commits TYPE STANDARD TABLE OF ty_commit WITH DEFAULT KEY.

    CLASS-METHODS find
      IMPORTING
        it_commits TYPE ty_commits
        iv_head_a  TYPE string
        iv_head_b  TYPE string
      RETURNING
        VALUE(rv_oid) TYPE string.
ENDCLASS.

CLASS zcl_hithub_merge_base IMPLEMENTATION.

  METHOD find.
    DATA lt_a TYPE ty_commits.
    DATA lt_pending TYPE ty_commits.
    DATA ls_visit TYPE ty_commit.
    DATA ls_commit TYPE ty_commit.
    DATA lv_index TYPE i.

    CLEAR rv_oid.
    IF iv_head_a IS INITIAL OR iv_head_b IS INITIAL.
      RETURN.
    ENDIF.

    ls_visit-oid = iv_head_a.
    APPEND ls_visit TO lt_a.
    lv_index = 1.
    WHILE lv_index <= lines( lt_a ).
      READ TABLE lt_a INDEX lv_index INTO ls_visit.
      lv_index = lv_index + 1.
      READ TABLE it_commits WITH KEY oid = ls_visit-oid INTO ls_commit.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF ls_commit-parent IS NOT INITIAL
          AND NOT line_exists( lt_a[ oid = ls_commit-parent ] ).
        CLEAR ls_visit.
        ls_visit-oid = ls_commit-parent.
        APPEND ls_visit TO lt_a.
      ENDIF.
      IF ls_commit-parent2 IS NOT INITIAL
          AND NOT line_exists( lt_a[ oid = ls_commit-parent2 ] ).
        CLEAR ls_visit.
        ls_visit-oid = ls_commit-parent2.
        APPEND ls_visit TO lt_a.
      ENDIF.
    ENDWHILE.

    CLEAR ls_visit.
    ls_visit-oid = iv_head_b.
    APPEND ls_visit TO lt_pending.
    lv_index = 1.
    WHILE lv_index <= lines( lt_pending ).
      READ TABLE lt_pending INDEX lv_index INTO ls_visit.
      lv_index = lv_index + 1.
      IF line_exists( lt_a[ oid = ls_visit-oid ] ).
        rv_oid = ls_visit-oid.
        RETURN.
      ENDIF.
      READ TABLE it_commits WITH KEY oid = ls_visit-oid INTO ls_commit.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF ls_commit-parent IS NOT INITIAL
          AND NOT line_exists( lt_pending[ oid = ls_commit-parent ] ).
        CLEAR ls_visit.
        ls_visit-oid = ls_commit-parent.
        APPEND ls_visit TO lt_pending.
      ENDIF.
      IF ls_commit-parent2 IS NOT INITIAL
          AND NOT line_exists( lt_pending[ oid = ls_commit-parent2 ] ).
        CLEAR ls_visit.
        ls_visit-oid = ls_commit-parent2.
        APPEND ls_visit TO lt_pending.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
