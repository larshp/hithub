CLASS ltcl_merge_base DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS finds_linear_base FOR TESTING RAISING cx_static_check.
    METHODS walks_merge_parents FOR TESTING RAISING cx_static_check.
    METHODS rejects_disconnected_graph FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_merge_base IMPLEMENTATION.

  METHOD finds_linear_base.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    lt_commits = VALUE #(
      ( oid = 'base' )
      ( oid = 'left' parent = 'base' )
      ( oid = 'right' parent = 'base' ) ).
    ASSERT zcl_hithub_merge_base=>find(
      it_commits = lt_commits iv_head_a = 'left' iv_head_b = 'right' ) = 'base'.
  ENDMETHOD.

  METHOD walks_merge_parents.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    lt_commits = VALUE #(
      ( oid = 'base' )
      ( oid = 'left' parent = 'base' )
      ( oid = 'right' parent = 'base' )
      ( oid = 'merge' parent = 'left' parent2 = 'right' ) ).
    ASSERT zcl_hithub_merge_base=>find(
      it_commits = lt_commits iv_head_a = 'merge' iv_head_b = 'right' ) = 'right'.
  ENDMETHOD.

  METHOD rejects_disconnected_graph.
    DATA lt_commits TYPE zcl_hithub_merge_base=>ty_commits.
    lt_commits = VALUE #(
      ( oid = 'left' ) ( oid = 'right' ) ).
    ASSERT zcl_hithub_merge_base=>find(
      it_commits = lt_commits iv_head_a = 'left' iv_head_b = 'right' ) IS INITIAL.
  ENDMETHOD.

ENDCLASS.
