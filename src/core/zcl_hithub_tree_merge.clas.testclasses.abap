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
    ASSERT ls_result-clean = abap_true.
    ASSERT lines( ls_result-conflicts ) = 0.
    ASSERT lines( ls_result-entries ) = 4.
    ASSERT line_exists( ls_result-entries[ path = 'ours.txt' ] ).
    ASSERT line_exists( ls_result-entries[ path = 'theirs.txt' ] ).
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
    ASSERT ls_result-clean = abap_false.
    ASSERT lines( ls_result-conflicts ) = 1.
    ASSERT line_exists( ls_result-conflicts[ path = 'conflict.txt' ] ).
    ASSERT lines( ls_result-entries ) = 0.
  ENDMETHOD.

ENDCLASS.
