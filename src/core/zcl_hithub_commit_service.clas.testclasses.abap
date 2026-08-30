CLASS ltcl_commit_service DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS lists_and_reads_commits FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_commit_service IMPLEMENTATION.

  METHOD lists_and_reads_commits.
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_objects) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_service) = NEW zcl_hithub_commit_service(
      io_metadata = lo_metadata io_objects = lo_objects ).
    DATA(lv_repository_id) = 'commit-service-history-test'.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_payload TYPE xstring.
    DATA lv_parent_oid TYPE string.
    DATA lv_head_oid TYPE string.
    DATA lv_written TYPE abap_bool.
    DATA lv_version TYPE int8.

    ls_commit-tree = '1111111111111111111111111111111111111111'.
    ls_commit-author = 'Alice <alice@example.com> 1704067200 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = 'Parent commit'.
    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    lv_parent_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_payload ).
    ls_object-key-repository_id = lv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = lv_parent_oid.
    ls_object-type = 'commit'.
    ls_object-size = xstrlen( lv_payload ).
    ls_object-payload = lv_payload.
    lv_written = lo_objects->zif_hithub_object_store~write( ls_object ).
    ASSERT lv_written = abap_true.

    CLEAR: ls_commit, ls_object.
    ls_commit-tree = '2222222222222222222222222222222222222222'.
    APPEND lv_parent_oid TO ls_commit-parents.
    ls_commit-author = 'Bob <bob@example.com> 1704067300 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = 'Head commit'.
    lv_payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    lv_head_oid = zcl_hithub_object_id=>calculate(
      iv_type = 'commit' iv_payload = lv_payload ).
    ls_object-key-repository_id = lv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = lv_head_oid.
    ls_object-type = 'commit'.
    ls_object-size = xstrlen( lv_payload ).
    ls_object-payload = lv_payload.
    lv_written = lo_objects->zif_hithub_object_store~write( ls_object ).
    ASSERT lv_written = abap_true.

    ls_reference-repository_id = lv_repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = lv_head_oid.
    lv_version = lo_metadata->zif_hithub_metadata_store~create_reference(
      ls_reference ).
    ASSERT lv_version = 1.

    DATA(lt_entries) = lo_service->list(
      iv_repository_id = lv_repository_id iv_ref = 'main' ).
    ASSERT lines( lt_entries ) = 2.
    ASSERT lt_entries[ 1 ]-oid = lv_head_oid.
    ASSERT lt_entries[ 1 ]-message = 'Head commit'.
    ASSERT lt_entries[ 2 ]-oid = lv_parent_oid.

    DATA(ls_entry) = lo_service->read(
      iv_repository_id = lv_repository_id
      iv_algorithm = 'sha1' iv_oid = lv_head_oid ).
    ASSERT ls_entry-author CS 'Bob'.
    ASSERT ls_entry-authored_at = '1704067300'.
    ASSERT ls_entry-parents[ 1 ] = lv_parent_oid.

    DATA(lv_json) = cl_abap_codepage=>convert_from(
      zcl_hithub_commit_repr=>one( ls_entry ) ).
    ASSERT lv_json CS '"message":"Head commit"'.
    ASSERT lv_json CS |"parents":["{ lv_parent_oid }"]|.
  ENDMETHOD.

ENDCLASS.
