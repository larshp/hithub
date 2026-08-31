CLASS ltcl_contents_service DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_author TYPE string VALUE 'Alice <alice@example.test> 100 +0000'.

    CLASS-DATA gv_sequence TYPE i.

    DATA mo_metadata TYPE REF TO zcl_hithub_local_meta_store.
    DATA mo_objects TYPE REF TO zcl_hithub_local_object_store.
    DATA mo_service TYPE REF TO zcl_hithub_contents_service.
    DATA mv_repository_id TYPE string.
    DATA mv_commit TYPE string.

    METHODS setup.
    METHODS browses_a_branch FOR TESTING RAISING cx_static_check.
    METHODS browses_a_commit_id FOR TESTING RAISING cx_static_check.
    METHODS browses_an_annotated_tag FOR TESTING RAISING cx_static_check.
    METHODS rejects_unknown_reference FOR TESTING RAISING cx_static_check.

    METHODS seed RAISING cx_static_check.

    METHODS write
      IMPORTING
        iv_type       TYPE string
        iv_payload    TYPE xstring
      RETURNING
        VALUE(rv_oid) TYPE string
      RAISING
        cx_static_check.

    METHODS reference
      IMPORTING
        iv_name TYPE string
        iv_oid  TYPE string
      RAISING
        cx_static_check.

    METHODS readme_at
      IMPORTING
        iv_ref         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        cx_static_check.
ENDCLASS.

CLASS ltcl_contents_service IMPLEMENTATION.

  METHOD setup.
    gv_sequence = gv_sequence + 1.
    mo_metadata = NEW zcl_hithub_local_meta_store( ).
    mo_objects = NEW zcl_hithub_local_object_store( ).
    mo_service = NEW zcl_hithub_contents_service(
      io_metadata = mo_metadata io_objects = mo_objects ).
    mv_repository_id = |contents-{ gv_sequence }|.
  ENDMETHOD.

  METHOD write.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    rv_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = iv_type iv_payload = iv_payload ).
    ls_object-key-repository_id = mv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = rv_oid.
    ls_object-type = iv_type.
    ls_object-size = xstrlen( iv_payload ).
    ls_object-payload = iv_payload.
    ASSERT NEW zcl_hithub_object_writer( mo_objects )->write(
      ls_object ) = abap_true.
  ENDMETHOD.

  METHOD reference.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    ls_reference-repository_id = mv_repository_id.
    ls_reference-name = iv_name.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = iv_oid.
    mo_metadata->zif_hithub_metadata_store~save_reference(
      is_reference = ls_reference iv_expected_version = 0 ).
  ENDMETHOD.

  METHOD seed.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_tag TYPE zcl_hithub_tag_codec=>ty_tag.

    DATA(lv_blob) = write(
      iv_type    = 'blob'
      iv_payload = cl_abap_codepage=>convert_to(
        |readme{ cl_abap_char_utilities=>newline }| ) ).
    ls_entry-mode = '100644'.
    ls_entry-name = 'README.md'.
    ls_entry-oid = CONV xstring( lv_blob ).
    APPEND ls_entry TO lt_entries.
    ls_commit-tree = write(
      iv_type = 'tree' iv_payload = zcl_hithub_tree_codec=>encode( lt_entries ) ).
    ls_commit-author = c_author.
    ls_commit-committer = c_author.
    ls_commit-message = 'Initial commit'.
    mv_commit = write(
      iv_type    = 'commit'
      iv_payload = zcl_hithub_commit_codec=>encode( ls_commit ) ).
    reference( iv_name = 'refs/heads/main' iv_oid = mv_commit ).

    ls_tag-object = mv_commit.
    ls_tag-type = 'commit'.
    ls_tag-tag = 'v1'.
    ls_tag-tagger = c_author.
    ls_tag-message = 'Release one'.
    reference(
      iv_name = 'refs/tags/v1'
      iv_oid  = write(
        iv_type = 'tag' iv_payload = zcl_hithub_tag_codec=>encode( ls_tag ) ) ).
  ENDMETHOD.

  METHOD readme_at.
    DATA(ls_object) = mo_service->read(
      iv_repository_id = mv_repository_id
      iv_ref           = iv_ref
      iv_path          = 'README.md' ).
    IF ls_object-key-oid IS INITIAL.
      RETURN.
    ENDIF.
    rv_text = cl_abap_codepage=>convert_from( ls_object-payload ).
  ENDMETHOD.

  METHOD browses_a_branch.
    seed( ).
    ASSERT lines( mo_service->list(
      iv_repository_id = mv_repository_id iv_ref = 'main' ) ) = 1.
    ASSERT readme_at( 'main' ) = |readme{ cl_abap_char_utilities=>newline }|.
    ASSERT readme_at( 'refs/heads/main' ) =
      |readme{ cl_abap_char_utilities=>newline }|.
  ENDMETHOD.

  METHOD browses_a_commit_id.
    seed( ).
    " The commits page links every row at its own commit id.
    ASSERT lines( mo_service->list(
      iv_repository_id = mv_repository_id iv_ref = mv_commit ) ) = 1.
    ASSERT readme_at( mv_commit ) = |readme{ cl_abap_char_utilities=>newline }|.
  ENDMETHOD.

  METHOD browses_an_annotated_tag.
    seed( ).
    " refs/tags/v1 points at a tag object that has to be peeled to a commit.
    ASSERT lines( mo_service->list(
      iv_repository_id = mv_repository_id iv_ref = 'v1' ) ) = 1.
    ASSERT readme_at( 'v1' ) = |readme{ cl_abap_char_utilities=>newline }|.
    ASSERT readme_at( 'refs/tags/v1' ) =
      |readme{ cl_abap_char_utilities=>newline }|.
  ENDMETHOD.

  METHOD rejects_unknown_reference.
    seed( ).
    ASSERT lines( mo_service->list(
      iv_repository_id = mv_repository_id iv_ref = 'absent' ) ) = 0.
    ASSERT readme_at( 'absent' ) IS INITIAL.
    ASSERT readme_at( '1111111111111111111111111111111111111111' ) IS INITIAL.
  ENDMETHOD.

ENDCLASS.
