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
    DATA ls_read TYPE zif_hithub_object_store=>ty_object.

    rv_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = iv_type iv_payload = iv_payload ).
    ls_object-key-repository_id = mv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = rv_oid.
    ls_object-type = iv_type.
    ls_object-size = xstrlen( iv_payload ).
    ls_object-payload = iv_payload.
    cl_abap_unit_assert=>assert_equals(
      act = strlen( rv_oid )
      exp = 40
      msg = |{ iv_type } did not hash to a 40 character sha1| ).
    " A committed row from an earlier run would make write( ) refuse.
    cl_abap_unit_assert=>assert_false(
      act = mo_objects->zif_hithub_object_store~contains( ls_object-key )
      msg = |a { iv_type } with oid { rv_oid } is already stored| ).
    cl_abap_unit_assert=>assert_true(
      act = NEW zcl_hithub_object_writer( mo_objects )->write(
        ls_object ) ).
    " Everything below reaches the object again through the store.
    ls_read = mo_objects->zif_hithub_object_store~read( ls_object-key ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-type
      exp = iv_type
      msg = |the stored { iv_type } does not read back as a { iv_type }| ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_read-payload
      exp = iv_payload
      msg = |the stored { iv_type } payload does not read back unchanged| ).
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
    DATA lt_decoded TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_decoded TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_tag TYPE zcl_hithub_tag_codec=>ty_tag.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_entry_oid TYPE string.

    DATA(lv_blob) = write(
      iv_type    = 'blob'
      iv_payload = cl_abap_codepage=>convert_to(
        |readme{ cl_abap_char_utilities=>newline }| ) ).
    ls_entry-mode = '100644'.
    ls_entry-name = 'README.md'.
    ls_entry-oid = CONV xstring( lv_blob ).
    cl_abap_unit_assert=>assert_equals(
      act = xstrlen( ls_entry-oid )
      exp = 20
      msg = 'the README blob oid does not convert to 20 bytes' ).
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

    " Walk the seeded chain once here, so a broken link is reported at this
    " line instead of as an empty listing in every test below.
    ls_reference = mo_metadata->zif_hithub_metadata_store~read_reference(
      iv_repository_id = mv_repository_id iv_name = 'refs/heads/main' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_reference-oid
      exp = mv_commit
      msg = 'refs/heads/main does not read back as the seeded commit' ).

    ls_key-repository_id = mv_repository_id.
    ls_key-algorithm = 'sha1'.
    ls_key-oid = mv_commit.
    ls_object = mo_objects->zif_hithub_object_store~read( ls_key ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_object-type
      exp = 'commit'
      msg = 'the seeded head does not read back as a commit' ).
    ls_decoded = zcl_hithub_commit_codec=>decode( ls_object-payload ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_decoded-tree
      exp = ls_commit-tree
      msg = 'the head commit does not decode back to its tree' ).

    ls_key-oid = ls_decoded-tree.
    ls_object = mo_objects->zif_hithub_object_store~read( ls_key ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_object-type
      exp = 'tree'
      msg = 'the root tree of the head commit cannot be read' ).
    lt_decoded = zcl_hithub_tree_codec=>decode( ls_object-payload ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_decoded )
      exp = 1
      msg = 'the root tree does not decode to one entry' ).
    READ TABLE lt_decoded INTO ls_entry INDEX 1.
    cl_abap_unit_assert=>assert_subrc( ).
    lv_entry_oid = ls_entry-oid.
    TRANSLATE lv_entry_oid TO LOWER CASE.
    cl_abap_unit_assert=>assert_equals(
      act = lv_entry_oid
      exp = lv_blob
      msg = 'the README entry does not point back at the README blob' ).
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
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_service->list(
        iv_repository_id = mv_repository_id iv_ref = 'main' ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = readme_at( 'main' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = readme_at( 'refs/heads/main' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
  ENDMETHOD.

  METHOD browses_a_commit_id.
    seed( ).
    " The commits page links every row at its own commit id.
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_service->list(
        iv_repository_id = mv_repository_id iv_ref = mv_commit ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = readme_at( mv_commit )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
  ENDMETHOD.

  METHOD browses_an_annotated_tag.
    seed( ).
    " refs/tags/v1 points at a tag object that has to be peeled to a commit.
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_service->list(
        iv_repository_id = mv_repository_id iv_ref = 'v1' ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = readme_at( 'v1' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
    cl_abap_unit_assert=>assert_equals(
      act = readme_at( 'refs/tags/v1' )
      exp = |readme{ cl_abap_char_utilities=>newline }| ).
  ENDMETHOD.

  METHOD rejects_unknown_reference.
    seed( ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_service->list(
        iv_repository_id = mv_repository_id iv_ref = 'absent' ) )
      exp = 0 ).
    cl_abap_unit_assert=>assert_initial( act = readme_at( 'absent' ) ).
    cl_abap_unit_assert=>assert_initial(
      act = readme_at( '1111111111111111111111111111111111111111' ) ).
  ENDMETHOD.

ENDCLASS.
