CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS allows_unprotected_ref FOR TESTING RAISING cx_static_check.
    METHODS rejects_protected_delete FOR TESTING RAISING cx_static_check.
    METHODS rejects_protected_force_push FOR TESTING RAISING cx_static_check.
    METHODS requires_configured_reviews FOR TESTING RAISING cx_static_check.
    METHODS allows_explicit_exceptions FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD allows_unprotected_ref.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.

    APPEND VALUE #( pattern = 'refs/heads/main' ) TO lt_rules.
    ASSERT zcl_hithub_branch_protection=>allows(
      it_rules = lt_rules iv_ref_name = 'refs/heads/feature'
      iv_is_delete = abap_false iv_is_force_push = abap_false
      iv_approved_reviews = 0 ) = abap_true.
  ENDMETHOD.

  METHOD rejects_protected_delete.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.

    APPEND VALUE #( pattern = 'refs/heads/main' ) TO lt_rules.
    ASSERT zcl_hithub_branch_protection=>allows(
      it_rules = lt_rules iv_ref_name = 'refs/heads/main'
      iv_is_delete = abap_true iv_is_force_push = abap_false
      iv_approved_reviews = 0 ) = abap_false.
  ENDMETHOD.

  METHOD rejects_protected_force_push.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.

    APPEND VALUE #( pattern = 'refs/heads/main' ) TO lt_rules.
    ASSERT zcl_hithub_branch_protection=>allows(
      it_rules = lt_rules iv_ref_name = 'refs/heads/main'
      iv_is_delete = abap_false iv_is_force_push = abap_true
      iv_approved_reviews = 0 ) = abap_false.
  ENDMETHOD.

  METHOD requires_configured_reviews.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.

    APPEND VALUE #( pattern = 'refs/heads/main' required_reviews = 2 )
      TO lt_rules.
    ASSERT zcl_hithub_branch_protection=>allows(
      it_rules = lt_rules iv_ref_name = 'refs/heads/main'
      iv_is_delete = abap_false iv_is_force_push = abap_false
      iv_approved_reviews = 1 ) = abap_false.
    ASSERT zcl_hithub_branch_protection=>allows(
      it_rules = lt_rules iv_ref_name = 'refs/heads/main'
      iv_is_delete = abap_false iv_is_force_push = abap_false
      iv_approved_reviews = 2 ) = abap_true.
  ENDMETHOD.

  METHOD allows_explicit_exceptions.
    DATA lt_rules TYPE zcl_hithub_branch_protection=>ty_rules.

    APPEND VALUE #( pattern = 'refs/heads/release*'
      allow_force_push = abap_true allow_delete = abap_true ) TO lt_rules.
    ASSERT zcl_hithub_branch_protection=>allows(
      it_rules = lt_rules iv_ref_name = 'refs/heads/release-1'
      iv_is_delete = abap_true iv_is_force_push = abap_true
      iv_approved_reviews = 0 ) = abap_true.
  ENDMETHOD.

ENDCLASS.
