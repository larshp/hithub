CLASS zcl_hithub_ref_distance DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_distance,
        ahead  TYPE i,
        behind TYPE i,
      END OF ty_distance.

    CLASS-METHODS calculate
      IMPORTING
        it_commits         TYPE zcl_hithub_merge_base=>ty_commits
        iv_head_a          TYPE string
        iv_head_b          TYPE string
      RETURNING
        VALUE(rs_distance) TYPE ty_distance.

  PRIVATE SECTION.
    CLASS-METHODS collect
      IMPORTING
        it_commits          TYPE zcl_hithub_merge_base=>ty_commits
        iv_head             TYPE string
      RETURNING
        VALUE(rt_reachable) TYPE zcl_hithub_merge_base=>ty_commits.
ENDCLASS.

CLASS zcl_hithub_ref_distance IMPLEMENTATION.

  METHOD calculate.
    DATA lt_a TYPE zcl_hithub_merge_base=>ty_commits.
    DATA lt_b TYPE zcl_hithub_merge_base=>ty_commits.
    DATA ls_commit TYPE zcl_hithub_merge_base=>ty_commit.

    CLEAR rs_distance.
    lt_a = collect( it_commits = it_commits iv_head = iv_head_a ).
    lt_b = collect( it_commits = it_commits iv_head = iv_head_b ).

    LOOP AT lt_a INTO ls_commit.
      IF NOT line_exists( lt_b[ oid = ls_commit-oid ] ).
        rs_distance-ahead = rs_distance-ahead + 1.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_b INTO ls_commit.
      IF NOT line_exists( lt_a[ oid = ls_commit-oid ] ).
        rs_distance-behind = rs_distance-behind + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD collect.
    DATA ls_visit TYPE zcl_hithub_merge_base=>ty_commit.
    DATA ls_commit TYPE zcl_hithub_merge_base=>ty_commit.
    DATA lv_index TYPE i.

    CLEAR rt_reachable.
    IF iv_head IS INITIAL.
      RETURN.
    ENDIF.

    ls_visit-oid = iv_head.
    APPEND ls_visit TO rt_reachable.
    lv_index = 1.
    WHILE lv_index <= lines( rt_reachable ).
      READ TABLE rt_reachable INDEX lv_index INTO ls_visit.
      lv_index = lv_index + 1.
      READ TABLE it_commits WITH KEY oid = ls_visit-oid INTO ls_commit.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF ls_commit-parent IS NOT INITIAL
          AND NOT line_exists( rt_reachable[ oid = ls_commit-parent ] ).
        CLEAR ls_visit.
        ls_visit-oid = ls_commit-parent.
        APPEND ls_visit TO rt_reachable.
      ENDIF.
      IF ls_commit-parent2 IS NOT INITIAL
          AND NOT line_exists( rt_reachable[ oid = ls_commit-parent2 ] ).
        CLEAR ls_visit.
        ls_visit-oid = ls_commit-parent2.
        APPEND ls_visit TO rt_reachable.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
