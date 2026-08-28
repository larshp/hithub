CLASS zcl_hithub_tree_merge DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_conflict,
        path TYPE string,
      END OF ty_conflict,
      ty_conflicts TYPE STANDARD TABLE OF ty_conflict WITH DEFAULT KEY,
      BEGIN OF ty_path,
        path TYPE string,
      END OF ty_path,
      ty_paths TYPE STANDARD TABLE OF ty_path WITH DEFAULT KEY,
      BEGIN OF ty_result,
        entries   TYPE zcl_hithub_changed_files=>ty_files,
        conflicts TYPE ty_conflicts,
        clean     TYPE abap_bool,
      END OF ty_result.

    CLASS-METHODS merge
      IMPORTING
        it_base   TYPE zcl_hithub_changed_files=>ty_files
        it_ours   TYPE zcl_hithub_changed_files=>ty_files
        it_theirs TYPE zcl_hithub_changed_files=>ty_files
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    CLASS-METHODS equal
      IMPORTING
        iv_exists_a TYPE abap_bool
        is_a        TYPE zcl_hithub_changed_files=>ty_file
        iv_exists_b TYPE abap_bool
        is_b        TYPE zcl_hithub_changed_files=>ty_file
      RETURNING
        VALUE(rv_equal) TYPE abap_bool.
ENDCLASS.

CLASS zcl_hithub_tree_merge IMPLEMENTATION.

  METHOD merge.
    DATA lt_paths TYPE ty_paths.
    DATA ls_path TYPE ty_path.
    DATA lv_path TYPE string.
    DATA ls_file TYPE zcl_hithub_changed_files=>ty_file.
    DATA ls_base TYPE zcl_hithub_changed_files=>ty_file.
    DATA ls_ours TYPE zcl_hithub_changed_files=>ty_file.
    DATA ls_theirs TYPE zcl_hithub_changed_files=>ty_file.
    DATA ls_conflict TYPE ty_conflict.
    DATA lv_base_found TYPE abap_bool.
    DATA lv_ours_found TYPE abap_bool.
    DATA lv_theirs_found TYPE abap_bool.

    CLEAR rs_result.
    rs_result-clean = abap_true.
    LOOP AT it_base INTO ls_file.
      READ TABLE lt_paths WITH KEY path = ls_file-path TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR ls_path.
        ls_path-path = ls_file-path.
        APPEND ls_path TO lt_paths.
      ENDIF.
    ENDLOOP.
    LOOP AT it_ours INTO ls_file.
      READ TABLE lt_paths WITH KEY path = ls_file-path TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR ls_path.
        ls_path-path = ls_file-path.
        APPEND ls_path TO lt_paths.
      ENDIF.
    ENDLOOP.
    LOOP AT it_theirs INTO ls_file.
      READ TABLE lt_paths WITH KEY path = ls_file-path TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR ls_path.
        ls_path-path = ls_file-path.
        APPEND ls_path TO lt_paths.
      ENDIF.
    ENDLOOP.
    SORT lt_paths BY path.

    LOOP AT lt_paths INTO ls_path.
      lv_path = ls_path-path.
      CLEAR: ls_base, ls_ours, ls_theirs.
      READ TABLE it_base WITH KEY path = lv_path INTO ls_base.
      lv_base_found = xsdbool( sy-subrc = 0 ).
      READ TABLE it_ours WITH KEY path = lv_path INTO ls_ours.
      lv_ours_found = xsdbool( sy-subrc = 0 ).
      READ TABLE it_theirs WITH KEY path = lv_path INTO ls_theirs.
      lv_theirs_found = xsdbool( sy-subrc = 0 ).

      IF equal(
          iv_exists_a = lv_ours_found is_a = ls_ours
          iv_exists_b = lv_theirs_found is_b = ls_theirs ) = abap_true.
        IF lv_ours_found = abap_true.
          APPEND ls_ours TO rs_result-entries.
        ENDIF.
      ELSEIF equal(
          iv_exists_a = lv_ours_found is_a = ls_ours
          iv_exists_b = lv_base_found is_b = ls_base ) = abap_true.
        IF lv_theirs_found = abap_true.
          APPEND ls_theirs TO rs_result-entries.
        ENDIF.
      ELSEIF equal(
          iv_exists_a = lv_theirs_found is_a = ls_theirs
          iv_exists_b = lv_base_found is_b = ls_base ) = abap_true.
        IF lv_ours_found = abap_true.
          APPEND ls_ours TO rs_result-entries.
        ENDIF.
      ELSE.
        CLEAR ls_conflict.
        ls_conflict-path = lv_path.
        APPEND ls_conflict TO rs_result-conflicts.
        rs_result-clean = abap_false.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD equal.
    rv_equal = abap_false.
    IF iv_exists_a <> iv_exists_b.
      RETURN.
    ENDIF.
    IF iv_exists_a = abap_false.
      rv_equal = abap_true.
      RETURN.
    ENDIF.
    rv_equal = xsdbool( is_a-oid = is_b-oid AND is_a-mode = is_b-mode ).
  ENDMETHOD.

ENDCLASS.
