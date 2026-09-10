CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS keeps_repository_refs FOR TESTING RAISING cx_static_check.
    METHODS rejects_foreign_and_bad_refs FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD keeps_repository_refs.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_visible TYPE zif_hithub_metadata_store=>ty_references.

    ls_reference-repository_id = 'repo-a'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    APPEND ls_reference TO lt_references.
    lt_visible = zcl_hithub_ref_visibility=>filter(
      iv_repository_id = 'repo-a' iv_algorithm = 'sha1'
      it_references = lt_references ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_visible ) exp = 1 ).
  ENDMETHOD.

  METHOD rejects_foreign_and_bad_refs.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_visible TYPE zif_hithub_metadata_store=>ty_references.

    ls_reference-repository_id = 'repo-b'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-oid = '1111111111111111111111111111111111111111'.
    APPEND ls_reference TO lt_references.
    ls_reference-repository_id = 'repo-a'.
    ls_reference-name = 'refs/heads/bad ref'.
    APPEND ls_reference TO lt_references.
    lt_visible = zcl_hithub_ref_visibility=>filter(
      iv_repository_id = 'repo-a' iv_algorithm = 'sha1'
      it_references = lt_references ).
    cl_abap_unit_assert=>assert_initial( act = lt_visible ).
  ENDMETHOD.

ENDCLASS.
