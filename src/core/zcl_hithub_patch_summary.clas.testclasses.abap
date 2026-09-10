CLASS ltcl_patch_summary DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS counts_change_kinds FOR TESTING RAISING cx_static_check.
    METHODS handles_empty_changes FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_patch_summary IMPLEMENTATION.

  METHOD counts_change_kinds.
    DATA lt_changes TYPE zcl_hithub_changed_files=>ty_changes.
    DATA ls_summary TYPE zcl_hithub_patch_summary=>ty_summary.
    lt_changes = VALUE #(
      ( path = 'a.txt' status = 'added' )
      ( path = 'b.txt' status = 'modified' )
      ( path = 'c.txt' status = 'modified' )
      ( path = 'd.txt' status = 'deleted' ) ).

    ls_summary = zcl_hithub_patch_summary=>generate( it_changes = lt_changes ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-total exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-added exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-modified exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-deleted exp = 1 ).
  ENDMETHOD.

  METHOD handles_empty_changes.
    DATA lt_changes TYPE zcl_hithub_changed_files=>ty_changes.
    DATA ls_summary TYPE zcl_hithub_patch_summary=>ty_summary.

    ls_summary = zcl_hithub_patch_summary=>generate( it_changes = lt_changes ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-total exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-added exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-modified exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = ls_summary-deleted exp = 0 ).
  ENDMETHOD.

ENDCLASS.
