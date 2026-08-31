CLASS lcl_hithub_failure_compression DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_compression.

ENDCLASS.

CLASS lcl_hithub_failure_quarantine DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_quarantine.
    METHODS discarded RETURNING VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mv_staged TYPE i.
    DATA mv_discarded TYPE i.

ENDCLASS.

CLASS lcl_hithub_failure_compression IMPLEMENTATION.

  METHOD zif_hithub_compression~compress.
    DATA lv_size TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_marker TYPE xstring.

    lv_size = xstrlen( iv_data ).
    IF lv_size > 255.
      RETURN.
    ENDIF.
    lv_marker = CONV xstring( 'F0' ).
    lv_byte = lv_size.
    CONCATENATE lv_marker lv_byte iv_data INTO rv_compressed IN BYTE MODE.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress.
    IF xstrlen( iv_data ) >= 2.
      rv_decompressed = iv_data+2.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress_stream.
    DATA lv_size TYPE i.
    DATA lv_byte TYPE x LENGTH 1.

    IF xstrlen( iv_data ) < 2 OR iv_data+0(1) <> CONV xstring( 'F0' ).
      RETURN.
    ENDIF.
    lv_byte = iv_data+1(1).
    lv_size = lv_byte.
    IF xstrlen( iv_data ) < lv_size + 2.
      RETURN.
    ENDIF.
    rs_result-raw_data = iv_data+2(lv_size).
    rs_result-consumed_bytes = lv_size + 2.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_hithub_failure_quarantine IMPLEMENTATION.

  METHOD zif_hithub_quarantine~stage.
    mv_staged = lines( it_objects ).
    rv_staged = mv_staged.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~promote.
    CLEAR rv_promoted.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~discard.
    CLEAR mv_staged.
    mv_discarded = mv_discarded + 1.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~count.
    rv_count = mv_staged.
  ENDMETHOD.

  METHOD discarded.
    rv_count = mv_discarded.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_hithub_receive_failure DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS promotion_failure_rolls_back FOR TESTING RAISING cx_static_check.
    METHODS batch_promote_rollback FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_hithub_receive_failure IMPLEMENTATION.

  METHOD promotion_failure_rolls_back.
    DATA(lo_compression) = NEW lcl_hithub_failure_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_quarantine) = NEW lcl_hithub_failure_quarantine( ).
    DATA(lo_receiver) = NEW zcl_hithub_pack_receiver(
      io_codec = lo_codec io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction io_quarantine = lo_quarantine ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_read TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_repository_id TYPE string.
    DATA lv_target_oid TYPE string.
    DATA lv_pack TYPE xstring.

    lv_repository_id = 'receive-failure-repository-1'.
    ls_object-key-repository_id = lv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-type = 'blob'.
    ls_object-payload = cl_abap_codepage=>convert_to( 'injected failure' ).
    ls_object-size = xstrlen( ls_object-payload ).
    lv_target_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = ls_object-type
      iv_payload = ls_object-payload ).
    ls_object-key-oid = lv_target_oid.
    APPEND ls_object TO lt_objects.
    lv_pack = lo_codec->repack( lt_objects ).

    ASSERT lo_receiver->receive(
      iv_pack = lv_pack iv_repository_id = lv_repository_id
      iv_ref_name = 'refs/heads/main' iv_target_oid = lv_target_oid ) =
      abap_false.
    ASSERT lo_quarantine->zif_hithub_quarantine~count( ) = 0.
    ASSERT lo_quarantine->discarded( ) = 1.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_object-key ) =
      abap_false.
    ls_read = lo_metadata->zif_hithub_metadata_store~read_reference(
      iv_repository_id = lv_repository_id iv_name = 'refs/heads/main' ).
    ASSERT ls_read-oid IS INITIAL.
    ASSERT lo_transaction->zif_hithub_transaction~is_active( ) = abap_false.
  ENDMETHOD.

  METHOD batch_promote_rollback.
    CONSTANTS lc_zero_oid TYPE string VALUE
      '0000000000000000000000000000000000000000'.
    DATA(lo_compression) = NEW lcl_hithub_failure_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_quarantine) = NEW lcl_hithub_failure_quarantine( ).
    DATA(lo_batch) = NEW zcl_hithub_receive_batch(
      io_codec = lo_codec io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction io_quarantine = lo_quarantine ).
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_command TYPE zcl_hithub_receive_request=>ty_command.
    DATA ls_read TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA lt_commands TYPE zcl_hithub_receive_request=>ty_commands.
    DATA lt_results TYPE zcl_hithub_receive_status=>ty_results.
    DATA lv_repository_id TYPE string.
    DATA lv_target_oid TYPE string.
    DATA lv_pack TYPE xstring.
    DATA lv_success TYPE abap_bool.

    lv_repository_id = 'batch-failure-repository-1'.
    ls_commit-tree = lc_zero_oid.
    ls_commit-author = 'Failure Tester <failure@example.test> 0 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = 'injected batch failure'.
    ls_object-key-repository_id = lv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-type = 'commit'.
    ls_object-payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    ls_object-size = xstrlen( ls_object-payload ).
    lv_target_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = ls_object-type
      iv_payload = ls_object-payload ).
    ls_object-key-oid = lv_target_oid.
    APPEND ls_object TO lt_objects.
    lv_pack = lo_codec->repack( lt_objects ).
    ls_command-old_oid = lc_zero_oid.
    ls_command-new_oid = lv_target_oid.
    ls_command-ref_name = 'refs/heads/main'.
    APPEND ls_command TO lt_commands.

    CALL METHOD lo_batch->apply
      EXPORTING
      iv_repository_id = lv_repository_id iv_pack = lv_pack
      it_commands = lt_commands
      IMPORTING
      et_results = lt_results rv_success = lv_success.
    ASSERT lv_success = abap_false.
    ASSERT lines( lt_results ) = 1.
    ASSERT lt_results[ 1 ]-ok = abap_false.
    ASSERT lo_quarantine->zif_hithub_quarantine~count( ) = 0.
    ASSERT lo_quarantine->discarded( ) = 1.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_object-key ) =
      abap_false.
    ls_read = lo_metadata->zif_hithub_metadata_store~read_reference(
      iv_repository_id = lv_repository_id iv_name = ls_command-ref_name ).
    ASSERT ls_read-oid IS INITIAL.
    ASSERT lo_transaction->zif_hithub_transaction~is_active( ) = abap_false.
  ENDMETHOD.

ENDCLASS.
