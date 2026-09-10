CLASS ltcl_tree_merge DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS merges_independent_paths FOR TESTING RAISING cx_static_check.
    METHODS reports_same_path_conflict FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_tree_merge IMPLEMENTATION.

  METHOD merges_independent_paths.
    DATA lt_base TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_ours TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_theirs TYPE zcl_hithub_changed_files=>ty_files.
    DATA ls_result TYPE zcl_hithub_tree_merge=>ty_result.
    lt_base = VALUE #(
      ( path = 'shared.txt' oid = 'base-shared' )
      ( path = 'unchanged.txt' oid = 'same' ) ).
    lt_ours = VALUE #(
      ( path = 'shared.txt' oid = 'base-shared' )
      ( path = 'unchanged.txt' oid = 'same' )
      ( path = 'ours.txt' oid = 'ours' ) ).
    lt_theirs = VALUE #(
      ( path = 'shared.txt' oid = 'base-shared' )
      ( path = 'unchanged.txt' oid = 'same' )
      ( path = 'theirs.txt' oid = 'theirs' ) ).

    ls_result = zcl_hithub_tree_merge=>merge(
      it_base = lt_base it_ours = lt_ours it_theirs = lt_theirs ).
    cl_abap_unit_assert=>assert_true( act = ls_result-clean ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-conflicts )
      exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-entries )
      exp = 4 ).
    READ TABLE ls_result-entries WITH KEY path = 'ours.txt'
      TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).
    READ TABLE ls_result-entries WITH KEY path = 'theirs.txt'
      TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).
  ENDMETHOD.

  METHOD reports_same_path_conflict.
    DATA lt_base TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_ours TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_theirs TYPE zcl_hithub_changed_files=>ty_files.
    DATA ls_result TYPE zcl_hithub_tree_merge=>ty_result.
    lt_base = VALUE #( ( path = 'conflict.txt' oid = 'base' ) ).
    lt_ours = VALUE #( ( path = 'conflict.txt' oid = 'ours' ) ).
    lt_theirs = VALUE #( ( path = 'conflict.txt' oid = 'theirs' ) ).

    ls_result = zcl_hithub_tree_merge=>merge(
      it_base = lt_base it_ours = lt_ours it_theirs = lt_theirs ).
    cl_abap_unit_assert=>assert_false( act = ls_result-clean ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-conflicts )
      exp = 1 ).
    READ TABLE ls_result-conflicts WITH KEY path = 'conflict.txt'
      TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-entries )
      exp = 0 ).
  ENDMETHOD.

ENDCLASS.
