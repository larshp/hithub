CLASS ltcl_unified_diff DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS reports_no_patch_when_equal FOR TESTING RAISING cx_static_check.
    METHODS replaces_single_line FOR TESTING RAISING cx_static_check.
    METHODS keeps_surrounding_context FOR TESTING RAISING cx_static_check.
    METHODS splits_distant_changes FOR TESTING RAISING cx_static_check.
    METHODS renders_added_file FOR TESTING RAISING cx_static_check.
    METHODS renders_deleted_file FOR TESTING RAISING cx_static_check.

    CLASS-METHODS text
      IMPORTING
        it_lines       TYPE ty_lines
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS ltcl_unified_diff IMPLEMENTATION.

  METHOD text.
    DATA lv_line TYPE string.

    CLEAR rv_text.
    LOOP AT it_lines INTO lv_line.
      rv_text = rv_text && lv_line && cl_abap_char_utilities=>newline.
    ENDLOOP.
  ENDMETHOD.

  METHOD reports_no_patch_when_equal.
    DATA ls_result TYPE zcl_hithub_unified_diff=>ty_result.

    ls_result = zcl_hithub_unified_diff=>build(
      iv_old_label = 'a/README'
      iv_new_label = 'b/README'
      iv_old       = |hello{ cl_abap_char_utilities=>newline }|
      iv_new       = |hello{ cl_abap_char_utilities=>newline }| ).
    ASSERT ls_result-patch IS INITIAL.
    ASSERT ls_result-additions = 0.
    ASSERT ls_result-deletions = 0.
  ENDMETHOD.

  METHOD replaces_single_line.
    DATA ls_result TYPE zcl_hithub_unified_diff=>ty_result.

    ls_result = zcl_hithub_unified_diff=>build(
      iv_old_label = 'a/README'
      iv_new_label = 'b/README'
      iv_old       = |hello{ cl_abap_char_utilities=>newline }|
      iv_new       = |feature{ cl_abap_char_utilities=>newline }| ).
    ASSERT ls_result-additions = 1.
    ASSERT ls_result-deletions = 1.
    ASSERT ls_result-patch CS '--- a/README'.
    ASSERT ls_result-patch CS '+++ b/README'.
    ASSERT ls_result-patch CS '@@ -1,1 +1,1 @@'.
    ASSERT ls_result-patch CS '-hello'.
    ASSERT ls_result-patch CS '+feature'.
  ENDMETHOD.

  METHOD keeps_surrounding_context.
    DATA ls_result TYPE zcl_hithub_unified_diff=>ty_result.
    DATA lt_old TYPE ty_lines.
    DATA lt_new TYPE ty_lines.

    lt_old = VALUE #( ( `one` ) ( `two` ) ( `three` ) ( `four` ) ( `five` ) ).
    lt_new = VALUE #( ( `one` ) ( `two` ) ( `THREE` ) ( `four` ) ( `five` ) ).
    ls_result = zcl_hithub_unified_diff=>build(
      iv_old_label = 'a/file'
      iv_new_label = 'b/file'
      iv_old       = text( lt_old )
      iv_new       = text( lt_new ) ).
    ASSERT ls_result-additions = 1.
    ASSERT ls_result-deletions = 1.
    ASSERT ls_result-patch CS '@@ -1,5 +1,5 @@'.
    ASSERT ls_result-patch CS '-three'.
    ASSERT ls_result-patch CS '+THREE'.
    ASSERT ls_result-patch CS ' one'.
    ASSERT ls_result-patch CS ' five'.
  ENDMETHOD.

  METHOD splits_distant_changes.
    DATA ls_result TYPE zcl_hithub_unified_diff=>ty_result.
    DATA lt_old TYPE ty_lines.
    DATA lt_new TYPE ty_lines.
    DATA lv_index TYPE i.
    DATA lv_line TYPE string.
    DATA lv_hunks TYPE i.

    APPEND `head` TO lt_old.
    lv_index = 1.
    WHILE lv_index <= 20.
      lv_line = |filler{ lv_index }|.
      APPEND lv_line TO lt_old.
      lv_index = lv_index + 1.
    ENDWHILE.
    APPEND `tail` TO lt_old.
    lt_new = lt_old.
    MODIFY lt_new INDEX 1 FROM `HEAD`.
    lv_index = lines( lt_new ).
    MODIFY lt_new INDEX lv_index FROM `TAIL`.

    ls_result = zcl_hithub_unified_diff=>build(
      iv_old_label = 'a/file'
      iv_new_label = 'b/file'
      iv_old       = text( lt_old )
      iv_new       = text( lt_new ) ).
    ASSERT ls_result-additions = 2.
    ASSERT ls_result-deletions = 2.
    FIND ALL OCCURRENCES OF '@@ -' IN ls_result-patch MATCH COUNT lv_hunks.
    ASSERT lv_hunks = 2.
  ENDMETHOD.

  METHOD renders_added_file.
    DATA ls_result TYPE zcl_hithub_unified_diff=>ty_result.

    ls_result = zcl_hithub_unified_diff=>build(
      iv_old_label = '/dev/null'
      iv_new_label = 'b/new.txt'
      iv_old       = ''
      iv_new       = |alpha{ cl_abap_char_utilities=>newline }| &&
                     |beta{ cl_abap_char_utilities=>newline }| ).
    ASSERT ls_result-additions = 2.
    ASSERT ls_result-deletions = 0.
    ASSERT ls_result-patch CS '--- /dev/null'.
    ASSERT ls_result-patch CS '@@ -0,0 +1,2 @@'.
    ASSERT ls_result-patch CS '+alpha'.
    ASSERT ls_result-patch CS '+beta'.
  ENDMETHOD.

  METHOD renders_deleted_file.
    DATA ls_result TYPE zcl_hithub_unified_diff=>ty_result.

    ls_result = zcl_hithub_unified_diff=>build(
      iv_old_label = 'a/gone.txt'
      iv_new_label = '/dev/null'
      iv_old       = |gone{ cl_abap_char_utilities=>newline }|
      iv_new       = '' ).
    ASSERT ls_result-additions = 0.
    ASSERT ls_result-deletions = 1.
    ASSERT ls_result-patch CS '+++ /dev/null'.
    ASSERT ls_result-patch CS '@@ -1,1 +0,0 @@'.
    ASSERT ls_result-patch CS '-gone'.
  ENDMETHOD.

ENDCLASS.
