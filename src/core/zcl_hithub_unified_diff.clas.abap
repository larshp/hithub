CLASS zcl_hithub_unified_diff DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_context TYPE i VALUE 3.
    CONSTANTS c_max_cells TYPE i VALUE 250000.

    TYPES:
      BEGIN OF ty_result,
        patch     TYPE string,
        additions TYPE i,
        deletions TYPE i,
      END OF ty_result.

    CLASS-METHODS build
      IMPORTING
        iv_old_label     TYPE string
        iv_new_label     TYPE string
        iv_old           TYPE string
        iv_new           TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    CONSTANTS c_context_kind TYPE string VALUE 'context'.
    CONSTANTS c_add_kind TYPE string VALUE 'add'.
    CONSTANTS c_delete_kind TYPE string VALUE 'delete'.

    TYPES ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    TYPES ty_numbers TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_operation,
        kind TYPE string,
        text TYPE string,
      END OF ty_operation,
      ty_operations TYPE STANDARD TABLE OF ty_operation WITH DEFAULT KEY.

    CLASS-METHODS split
      IMPORTING
        iv_text         TYPE string
      RETURNING
        VALUE(rt_lines) TYPE ty_lines.

    CLASS-METHODS script
      IMPORTING
        it_old               TYPE ty_lines
        it_new               TYPE ty_lines
      RETURNING
        VALUE(rt_operations) TYPE ty_operations.

    CLASS-METHODS middle
      IMPORTING
        it_old        TYPE ty_lines
        it_new        TYPE ty_lines
        iv_old_offset TYPE i
        iv_old_count  TYPE i
        iv_new_offset TYPE i
        iv_new_count  TYPE i
      CHANGING
        ct_operations TYPE ty_operations.

    CLASS-METHODS replacement
      IMPORTING
        it_old        TYPE ty_lines
        it_new        TYPE ty_lines
        iv_old_offset TYPE i
        iv_old_count  TYPE i
        iv_new_offset TYPE i
        iv_new_count  TYPE i
      CHANGING
        ct_operations TYPE ty_operations.

    CLASS-METHODS append_operation
      IMPORTING
        iv_kind       TYPE string
        iv_text       TYPE string
      CHANGING
        ct_operations TYPE ty_operations.

    CLASS-METHODS render
      IMPORTING
        it_operations   TYPE ty_operations
        iv_old_label    TYPE string
        iv_new_label    TYPE string
      RETURNING
        VALUE(rv_patch) TYPE string.
ENDCLASS.

CLASS zcl_hithub_unified_diff IMPLEMENTATION.

  METHOD build.
    DATA lt_old TYPE ty_lines.
    DATA lt_new TYPE ty_lines.
    DATA lt_operations TYPE ty_operations.
    DATA ls_operation TYPE ty_operation.

    CLEAR rs_result.
    IF iv_old = iv_new.
      RETURN.
    ENDIF.
    lt_old = split( iv_old ).
    lt_new = split( iv_new ).
    lt_operations = script( it_old = lt_old it_new = lt_new ).
    LOOP AT lt_operations INTO ls_operation.
      CASE ls_operation-kind.
        WHEN c_add_kind.
          rs_result-additions = rs_result-additions + 1.
        WHEN c_delete_kind.
          rs_result-deletions = rs_result-deletions + 1.
      ENDCASE.
    ENDLOOP.
    IF rs_result-additions = 0 AND rs_result-deletions = 0.
      RETURN.
    ENDIF.
    rs_result-patch = render(
      it_operations = lt_operations
      iv_old_label  = iv_old_label
      iv_new_label  = iv_new_label ).
  ENDMETHOD.

  METHOD split.
    DATA lv_last TYPE string.
    DATA lv_lines TYPE i.

    CLEAR rt_lines.
    IF iv_text IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT iv_text AT cl_abap_char_utilities=>newline INTO TABLE rt_lines.
    lv_lines = lines( rt_lines ).
    IF lv_lines = 0.
      RETURN.
    ENDIF.
    READ TABLE rt_lines INDEX lv_lines INTO lv_last.
    IF lv_last IS INITIAL.
      DELETE rt_lines INDEX lv_lines.
    ENDIF.
  ENDMETHOD.

  METHOD script.
    DATA lv_old_lines TYPE i.
    DATA lv_new_lines TYPE i.
    DATA lv_prefix TYPE i.
    DATA lv_suffix TYPE i.
    DATA lv_index TYPE i.
    DATA lv_old_line TYPE string.
    DATA lv_new_line TYPE string.

    CLEAR rt_operations.
    lv_old_lines = lines( it_old ).
    lv_new_lines = lines( it_new ).

    WHILE lv_prefix < lv_old_lines AND lv_prefix < lv_new_lines.
      lv_index = lv_prefix + 1.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      READ TABLE it_new INDEX lv_index INTO lv_new_line.
      IF lv_old_line <> lv_new_line.
        EXIT.
      ENDIF.
      lv_prefix = lv_prefix + 1.
    ENDWHILE.

    WHILE lv_prefix + lv_suffix < lv_old_lines
        AND lv_prefix + lv_suffix < lv_new_lines.
      lv_index = lv_old_lines - lv_suffix.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      lv_index = lv_new_lines - lv_suffix.
      READ TABLE it_new INDEX lv_index INTO lv_new_line.
      IF lv_old_line <> lv_new_line.
        EXIT.
      ENDIF.
      lv_suffix = lv_suffix + 1.
    ENDWHILE.

    lv_index = 1.
    WHILE lv_index <= lv_prefix.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      append_operation(
        EXPORTING iv_kind = c_context_kind iv_text = lv_old_line
        CHANGING ct_operations = rt_operations ).
      lv_index = lv_index + 1.
    ENDWHILE.

    middle(
      EXPORTING
        it_old        = it_old
        it_new        = it_new
        iv_old_offset = lv_prefix
        iv_old_count  = lv_old_lines - lv_prefix - lv_suffix
        iv_new_offset = lv_prefix
        iv_new_count  = lv_new_lines - lv_prefix - lv_suffix
      CHANGING
        ct_operations = rt_operations ).

    lv_index = lv_old_lines - lv_suffix + 1.
    WHILE lv_index <= lv_old_lines.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      append_operation(
        EXPORTING iv_kind = c_context_kind iv_text = lv_old_line
        CHANGING ct_operations = rt_operations ).
      lv_index = lv_index + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD middle.
    DATA lt_matrix TYPE ty_numbers.
    DATA lv_cells TYPE i.
    DATA lv_zero TYPE i.
    DATA lv_row TYPE i.
    DATA lv_column TYPE i.
    DATA lv_stride TYPE i.
    DATA lv_base TYPE i.
    DATA lv_next TYPE i.
    DATA lv_target TYPE i.
    DATA lv_value TYPE i.
    DATA lv_down TYPE i.
    DATA lv_right TYPE i.
    DATA lv_index TYPE i.
    DATA lv_old_line TYPE string.
    DATA lv_new_line TYPE string.

    IF iv_old_count <= 0 AND iv_new_count <= 0.
      RETURN.
    ENDIF.
    IF iv_old_count <= 0 OR iv_new_count <= 0
        OR iv_old_count * iv_new_count > c_max_cells.
      replacement(
        EXPORTING
          it_old        = it_old
          it_new        = it_new
          iv_old_offset = iv_old_offset
          iv_old_count  = iv_old_count
          iv_new_offset = iv_new_offset
          iv_new_count  = iv_new_count
        CHANGING
          ct_operations = ct_operations ).
      RETURN.
    ENDIF.

    lv_stride = iv_new_count + 1.
    lv_cells = ( iv_old_count + 1 ) * lv_stride.
    DO lv_cells TIMES.
      APPEND lv_zero TO lt_matrix.
    ENDDO.

    lv_row = iv_old_count - 1.
    WHILE lv_row >= 0.
      lv_index = iv_old_offset + lv_row + 1.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      lv_base = lv_row * lv_stride.
      lv_next = lv_base + lv_stride.
      lv_column = iv_new_count - 1.
      WHILE lv_column >= 0.
        lv_index = iv_new_offset + lv_column + 1.
        READ TABLE it_new INDEX lv_index INTO lv_new_line.
        IF lv_old_line = lv_new_line.
          lv_index = lv_next + lv_column + 2.
          READ TABLE lt_matrix INDEX lv_index INTO lv_value.
          lv_value = lv_value + 1.
        ELSE.
          lv_index = lv_next + lv_column + 1.
          READ TABLE lt_matrix INDEX lv_index INTO lv_down.
          lv_index = lv_base + lv_column + 2.
          READ TABLE lt_matrix INDEX lv_index INTO lv_right.
          IF lv_down >= lv_right.
            lv_value = lv_down.
          ELSE.
            lv_value = lv_right.
          ENDIF.
        ENDIF.
        lv_target = lv_base + lv_column + 1.
        MODIFY lt_matrix INDEX lv_target FROM lv_value.
        lv_column = lv_column - 1.
      ENDWHILE.
      lv_row = lv_row - 1.
    ENDWHILE.

    lv_row = 0.
    lv_column = 0.
    WHILE lv_row < iv_old_count AND lv_column < iv_new_count.
      lv_index = iv_old_offset + lv_row + 1.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      lv_index = iv_new_offset + lv_column + 1.
      READ TABLE it_new INDEX lv_index INTO lv_new_line.
      IF lv_old_line = lv_new_line.
        append_operation(
          EXPORTING iv_kind = c_context_kind iv_text = lv_old_line
          CHANGING ct_operations = ct_operations ).
        lv_row = lv_row + 1.
        lv_column = lv_column + 1.
        CONTINUE.
      ENDIF.
      lv_index = ( lv_row + 1 ) * lv_stride + lv_column + 1.
      READ TABLE lt_matrix INDEX lv_index INTO lv_down.
      lv_index = lv_row * lv_stride + lv_column + 2.
      READ TABLE lt_matrix INDEX lv_index INTO lv_right.
      IF lv_down >= lv_right.
        append_operation(
          EXPORTING iv_kind = c_delete_kind iv_text = lv_old_line
          CHANGING ct_operations = ct_operations ).
        lv_row = lv_row + 1.
      ELSE.
        append_operation(
          EXPORTING iv_kind = c_add_kind iv_text = lv_new_line
          CHANGING ct_operations = ct_operations ).
        lv_column = lv_column + 1.
      ENDIF.
    ENDWHILE.

    WHILE lv_row < iv_old_count.
      lv_index = iv_old_offset + lv_row + 1.
      READ TABLE it_old INDEX lv_index INTO lv_old_line.
      append_operation(
        EXPORTING iv_kind = c_delete_kind iv_text = lv_old_line
        CHANGING ct_operations = ct_operations ).
      lv_row = lv_row + 1.
    ENDWHILE.
    WHILE lv_column < iv_new_count.
      lv_index = iv_new_offset + lv_column + 1.
      READ TABLE it_new INDEX lv_index INTO lv_new_line.
      append_operation(
        EXPORTING iv_kind = c_add_kind iv_text = lv_new_line
        CHANGING ct_operations = ct_operations ).
      lv_column = lv_column + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD replacement.
    DATA lv_index TYPE i.
    DATA lv_position TYPE i.
    DATA lv_line TYPE string.

    lv_index = 1.
    WHILE lv_index <= iv_old_count.
      lv_position = iv_old_offset + lv_index.
      READ TABLE it_old INDEX lv_position INTO lv_line.
      append_operation(
        EXPORTING iv_kind = c_delete_kind iv_text = lv_line
        CHANGING ct_operations = ct_operations ).
      lv_index = lv_index + 1.
    ENDWHILE.
    lv_index = 1.
    WHILE lv_index <= iv_new_count.
      lv_position = iv_new_offset + lv_index.
      READ TABLE it_new INDEX lv_position INTO lv_line.
      append_operation(
        EXPORTING iv_kind = c_add_kind iv_text = lv_line
        CHANGING ct_operations = ct_operations ).
      lv_index = lv_index + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD append_operation.
    DATA ls_operation TYPE ty_operation.

    ls_operation-kind = iv_kind.
    ls_operation-text = iv_text.
    APPEND ls_operation TO ct_operations.
  ENDMETHOD.

  METHOD render.
    DATA lt_old_numbers TYPE ty_numbers.
    DATA lt_new_numbers TYPE ty_numbers.
    DATA ls_operation TYPE ty_operation.
    DATA lv_total TYPE i.
    DATA lv_old_seen TYPE i.
    DATA lv_new_seen TYPE i.
    DATA lv_index TYPE i.
    DATA lv_scan TYPE i.
    DATA lv_last_change TYPE i.
    DATA lv_start TYPE i.
    DATA lv_end TYPE i.
    DATA lv_before TYPE i.
    DATA lv_old_before TYPE i.
    DATA lv_new_before TYPE i.
    DATA lv_old_count TYPE i.
    DATA lv_new_count TYPE i.
    DATA lv_old_start TYPE i.
    DATA lv_new_start TYPE i.

    CLEAR rv_patch.
    lv_total = lines( it_operations ).
    IF lv_total = 0.
      RETURN.
    ENDIF.
    LOOP AT it_operations INTO ls_operation.
      IF ls_operation-kind <> c_add_kind.
        lv_old_seen = lv_old_seen + 1.
      ENDIF.
      IF ls_operation-kind <> c_delete_kind.
        lv_new_seen = lv_new_seen + 1.
      ENDIF.
      APPEND lv_old_seen TO lt_old_numbers.
      APPEND lv_new_seen TO lt_new_numbers.
    ENDLOOP.

    rv_patch = |--- { iv_old_label }| && cl_abap_char_utilities=>newline
      && |+++ { iv_new_label }|.

    lv_index = 1.
    WHILE lv_index <= lv_total.
      READ TABLE it_operations INDEX lv_index INTO ls_operation.
      IF ls_operation-kind = c_context_kind.
        lv_index = lv_index + 1.
        CONTINUE.
      ENDIF.
      lv_start = lv_index - c_context.
      IF lv_start < 1.
        lv_start = 1.
      ENDIF.
      lv_last_change = lv_index.
      lv_scan = lv_index + 1.
      WHILE lv_scan <= lv_total.
        READ TABLE it_operations INDEX lv_scan INTO ls_operation.
        IF ls_operation-kind <> c_context_kind.
          lv_last_change = lv_scan.
        ELSEIF lv_scan - lv_last_change > 2 * c_context.
          EXIT.
        ENDIF.
        lv_scan = lv_scan + 1.
      ENDWHILE.
      lv_end = lv_last_change + c_context.
      IF lv_end > lv_total.
        lv_end = lv_total.
      ENDIF.

      CLEAR: lv_old_before, lv_new_before.
      IF lv_start > 1.
        lv_before = lv_start - 1.
        READ TABLE lt_old_numbers INDEX lv_before INTO lv_old_before.
        READ TABLE lt_new_numbers INDEX lv_before INTO lv_new_before.
      ENDIF.
      READ TABLE lt_old_numbers INDEX lv_end INTO lv_old_count.
      READ TABLE lt_new_numbers INDEX lv_end INTO lv_new_count.
      lv_old_count = lv_old_count - lv_old_before.
      lv_new_count = lv_new_count - lv_new_before.
      IF lv_old_count = 0.
        lv_old_start = lv_old_before.
      ELSE.
        lv_old_start = lv_old_before + 1.
      ENDIF.
      IF lv_new_count = 0.
        lv_new_start = lv_new_before.
      ELSE.
        lv_new_start = lv_new_before + 1.
      ENDIF.
      rv_patch = rv_patch && cl_abap_char_utilities=>newline
        && |@@ -{ lv_old_start },{ lv_old_count } |
        && |+{ lv_new_start },{ lv_new_count } @@|.

      lv_scan = lv_start.
      WHILE lv_scan <= lv_end.
        READ TABLE it_operations INDEX lv_scan INTO ls_operation.
        rv_patch = rv_patch && cl_abap_char_utilities=>newline.
        CASE ls_operation-kind.
          WHEN c_add_kind.
            rv_patch = rv_patch && |+{ ls_operation-text }|.
          WHEN c_delete_kind.
            rv_patch = rv_patch && |-{ ls_operation-text }|.
          WHEN OTHERS.
            rv_patch = rv_patch && | { ls_operation-text }|.
        ENDCASE.
        lv_scan = lv_scan + 1.
      ENDWHILE.
      lv_index = lv_end + 1.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
