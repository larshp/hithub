CLASS ltcl_ref_distance DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS counts_divergent_refs FOR TESTING RAISING cx_static_check.
    METHODS counts_ancestor_ref FOR TESTING RAISING cx_static_check.
    METHODS counts_merge_history FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_ref_distance IMPLEMENTATION.

  METHOD counts_divergent_refs.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    DATA ls_distance TYPE zcl_hithub_ref_distance=>ty_distance.
    lt_commits = VALUE #(
      ( oid = 'base' )
      ( oid = 'left' parent = 'base' )
      ( oid = 'right' parent = 'base' ) ).
    ls_distance = zcl_hithub_ref_distance=>calculate(
      it_commits = lt_commits iv_head_a = 'left' iv_head_b = 'right' ).
    ASSERT ls_distance-ahead = 1.
    ASSERT ls_distance-behind = 1.
  ENDMETHOD.

  METHOD counts_ancestor_ref.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    DATA ls_distance TYPE zcl_hithub_ref_distance=>ty_distance.
    lt_commits = VALUE #(
      ( oid = 'base' )
      ( oid = 'tip' parent = 'base' ) ).
    ls_distance = zcl_hithub_ref_distance=>calculate(
      it_commits = lt_commits iv_head_a = 'base' iv_head_b = 'tip' ).
    ASSERT ls_distance-ahead = 0.
    ASSERT ls_distance-behind = 1.
  ENDMETHOD.

  METHOD counts_merge_history.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    DATA ls_distance TYPE zcl_hithub_ref_distance=>ty_distance.
    lt_commits = VALUE #(
      ( oid = 'base' )
      ( oid = 'left' parent = 'base' )
      ( oid = 'right' parent = 'base' )
      ( oid = 'merge' parent = 'left' parent2 = 'right' ) ).
    ls_distance = zcl_hithub_ref_distance=>calculate(
      it_commits = lt_commits iv_head_a = 'merge' iv_head_b = 'right' ).
    ASSERT ls_distance-ahead = 2.
    ASSERT ls_distance-behind = 0.
  ENDMETHOD.

ENDCLASS.
