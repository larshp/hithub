CLASS lcl_pack_compression DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_compression.

ENDCLASS.

CLASS lcl_receive_quarantine DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_quarantine.
    METHODS staged RETURNING VALUE(rv_count) TYPE i.
    METHODS promoted RETURNING VALUE(rv_count) TYPE i.

  PRIVATE SECTION.
    DATA mv_staged TYPE i.
    DATA mv_promoted TYPE i.

ENDCLASS.

CLASS lcl_receive_event_sink DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_event_sink.
    METHODS event RETURNING VALUE(rs_event) TYPE zif_hithub_event_sink=>ty_event.

  PRIVATE SECTION.
    DATA ms_event TYPE zif_hithub_event_sink=>ty_event.

ENDCLASS.

CLASS lcl_receive_event_sink IMPLEMENTATION.

  METHOD zif_hithub_event_sink~emit.
    ms_event = is_event.
  ENDMETHOD.

  METHOD event.
    rs_event = ms_event.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_receive_clock DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_clock.

ENDCLASS.

CLASS lcl_receive_clock IMPLEMENTATION.

  METHOD zif_hithub_clock~now.
    rv_timestamp = '20260828123456.0000000'.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_receive_quarantine IMPLEMENTATION.

  METHOD zif_hithub_quarantine~stage.
    mv_staged = lines( it_objects ).
    rv_staged = mv_staged.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~promote.
    mv_promoted = mv_staged.
    rv_promoted = mv_promoted.
    CLEAR mv_staged.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~discard.
    CLEAR mv_staged.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~count.
    rv_count = mv_staged.
  ENDMETHOD.

  METHOD staged.
    rv_count = mv_staged.
  ENDMETHOD.

  METHOD promoted.
    rv_count = mv_promoted.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pack_compression IMPLEMENTATION.

  METHOD zif_hithub_compression~compress.
    DATA lv_size TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_marker TYPE xstring.

    lv_size = xstrlen( iv_data ).
    IF lv_size > 255.
      CLEAR rv_compressed.
      RETURN.
    ENDIF.
    lv_marker = CONV xstring( 'F0' ).
    lv_byte = lv_size.
    CONCATENATE lv_marker lv_byte iv_data INTO rv_compressed IN BYTE MODE.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress.
    rv_decompressed = iv_data+2.
  ENDMETHOD.

  METHOD zif_hithub_compression~decompress_stream.
    DATA lv_size TYPE i.
    DATA lv_byte TYPE x LENGTH 1.

    CLEAR rs_result.
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

CLASS lcl_pack_object_store DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_object_store.

    METHODS constructor
      IMPORTING
        it_objects TYPE zcl_hithub_pack_codec=>ty_objects.

  PRIVATE SECTION.
    DATA mt_objects TYPE zcl_hithub_pack_codec=>ty_objects.

ENDCLASS.

CLASS lcl_pack_object_store IMPLEMENTATION.

  METHOD constructor.
    mt_objects = it_objects.
  ENDMETHOD.

  METHOD zif_hithub_object_store~read.
    READ TABLE mt_objects INTO rs_object
      WITH KEY key-repository_id = is_key-repository_id
        key-algorithm = is_key-algorithm key-oid = is_key-oid.
  ENDMETHOD.

  METHOD zif_hithub_object_store~contains.
    READ TABLE mt_objects TRANSPORTING NO FIELDS
      WITH KEY key-repository_id = is_key-repository_id
        key-algorithm = is_key-algorithm key-oid = is_key-oid.
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_object_store~write.
    rv_created = abap_false.
  ENDMETHOD.

  METHOD zif_hithub_object_store~purge_repository.
    rv_purged = abap_true.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS round_trips_multiple_objects FOR TESTING RAISING cx_static_check.
    METHODS round_trips_reachable_objects FOR TESTING RAISING cx_static_check.
    METHODS rejects_corrupt_pack FOR TESTING RAISING cx_static_check.
    METHODS rejects_malformed_pack FOR TESTING RAISING cx_static_check.
    METHODS rejects_pack_before_ref_update FOR TESTING RAISING cx_static_check.
    METHODS rejects_pack_over_limit FOR TESTING RAISING cx_static_check.
    METHODS promotes_before_ref_save FOR TESTING RAISING cx_static_check.
    METHODS unpacks_delta_objects FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD round_trips_multiple_objects.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA lt_unpacked TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_read TYPE zif_hithub_object_store=>ty_object.
    DATA lv_pack TYPE xstring.
    DATA lv_oid TYPE string.

    ls_object-key-repository_id = 'pack-roundtrip-repository-000000'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-type = 'blob'.
    ls_object-payload = cl_abap_codepage=>convert_to( 'hello' ).
    ls_object-size = xstrlen( ls_object-payload ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = ls_object-type iv_payload = ls_object-payload ).
    ls_object-key-oid = lv_oid.
    APPEND ls_object TO lt_objects.

    ls_object-payload = cl_abap_codepage=>convert_to( 'world!' ).
    ls_object-size = xstrlen( ls_object-payload ).
    lv_oid = zcl_hithub_object_id=>calculate(
      iv_type = ls_object-type iv_payload = ls_object-payload ).
    ls_object-key-oid = lv_oid.
    APPEND ls_object TO lt_objects.

    lv_pack = lo_codec->repack( lt_objects ).
    lt_unpacked = lo_codec->unpack(
      iv_pack          = lv_pack
      iv_repository_id = 'pack-roundtrip-repository-000000' ).

    ASSERT lines( lt_unpacked ) = 2.
    LOOP AT lt_objects INTO ls_object.
      READ TABLE lt_unpacked INTO ls_read
        WITH KEY key-oid = ls_object-key-oid.
      ASSERT sy-subrc = 0.
      ASSERT ls_read-payload = ls_object-payload.
    ENDLOOP.
  ENDMETHOD.

  METHOD round_trips_reachable_objects.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA lt_unpacked TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA lt_roundtrip TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA lt_reachable TYPE zcl_hithub_reachability=>ty_keys.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA ls_blob TYPE zif_hithub_object_store=>ty_object.
    DATA ls_tree TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA lv_repository_id TYPE string.
    DATA lv_pack TYPE xstring.
    DATA lv_oid TYPE string.
    DATA lo_store TYPE REF TO lcl_pack_object_store.
    DATA lo_reader TYPE REF TO zcl_hithub_object_reader.
    DATA lo_reachability TYPE REF TO zcl_hithub_reachability.

    lv_repository_id = 'pack-reachable-repository-000000'.

    ls_blob-key-repository_id = lv_repository_id.
    ls_blob-key-algorithm = 'sha1'.
    ls_blob-type = 'blob'.
    ls_blob-payload = cl_abap_codepage=>convert_to( source = 'reachable payload' ).
    ls_blob-size = xstrlen( ls_blob-payload ).
    ls_blob-key-oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = ls_blob-type iv_payload = ls_blob-payload ).

    ls_entry-mode = '100644'.
    ls_entry-name = 'reachable.txt'.
    ls_entry-oid = CONV xstring( ls_blob-key-oid ).
    APPEND ls_entry TO lt_entries.
    ls_tree-key-repository_id = lv_repository_id.
    ls_tree-key-algorithm = 'sha1'.
    ls_tree-type = 'tree'.
    ls_tree-payload = zcl_hithub_tree_codec=>encode( lt_entries ).
    ls_tree-size = xstrlen( ls_tree-payload ).
    ls_tree-key-oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = ls_tree-type iv_payload = ls_tree-payload ).

    ls_commit-tree = ls_tree-key-oid.
    ls_commit-author = 'Alice <alice@example.com> 0 +0000'.
    ls_commit-committer = ls_commit-author.
    ls_commit-message = 'reachable commit'.
    ls_commit_object-key-repository_id = lv_repository_id.
    ls_commit_object-key-algorithm = 'sha1'.
    ls_commit_object-type = 'commit'.
    ls_commit_object-payload = zcl_hithub_commit_codec=>encode( ls_commit ).
    ls_commit_object-size = xstrlen( ls_commit_object-payload ).
    ls_commit_object-key-oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1'
      iv_type      = ls_commit_object-type
      iv_payload   = ls_commit_object-payload ).

    APPEND ls_commit_object TO lt_objects.
    APPEND ls_tree TO lt_objects.
    APPEND ls_blob TO lt_objects.
    lv_pack = lo_codec->repack( lt_objects ).
    lt_unpacked = lo_codec->unpack(
      iv_pack = lv_pack iv_repository_id = lv_repository_id ).
    lv_pack = lo_codec->repack( lt_unpacked ).
    lt_roundtrip = lo_codec->unpack(
      iv_pack = lv_pack iv_repository_id = lv_repository_id ).

    lo_store = NEW lcl_pack_object_store( lt_roundtrip ).
    lo_reader = NEW zcl_hithub_object_reader( lo_store ).
    lo_reachability = NEW zcl_hithub_reachability( lo_reader ).
    lt_reachable = lo_reachability->walk( ls_commit_object-key ).

    ASSERT lines( lt_reachable ) = 3.
    LOOP AT lt_reachable INTO ls_key.
      READ TABLE lt_roundtrip INTO ls_object
        WITH KEY key-repository_id = ls_key-repository_id
          key-algorithm = ls_key-algorithm key-oid = ls_key-oid.
      ASSERT sy-subrc = 0.
    ENDLOOP.
  ENDMETHOD.

  METHOD rejects_corrupt_pack.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_pack TYPE xstring.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_last_offset TYPE i.
    DATA lv_pack_body TYPE xstring.

    ls_object-type = 'blob'.
    ls_object-payload = cl_abap_codepage=>convert_to( source = 'safe' ).
    ls_object-size = 4.
    APPEND ls_object TO lt_objects.
    lv_pack = lo_codec->repack( lt_objects ).
    lv_last_offset = xstrlen( lv_pack ) - 1.
    lv_byte = lv_pack+lv_last_offset(1).
    lv_byte = lv_byte BIT-XOR CONV xstring( '01' ).
    lv_pack_body = lv_pack+0(lv_last_offset).
    CONCATENATE lv_pack_body lv_byte INTO lv_pack IN BYTE MODE.

    ASSERT lo_codec->unpack(
      iv_pack = lv_pack iv_repository_id = 'pack-corrupt-repository' ) IS INITIAL.
  ENDMETHOD.

  METHOD rejects_malformed_pack.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA lv_header TYPE xstring.
    DATA lv_body TYPE xstring.
    DATA lv_pack TYPE xstring.
    DATA lv_digest TYPE xstring.

    lv_header = zcl_hithub_pack_header=>build( 1 ).
    lv_body = CONV xstring( '30' ).
    CONCATENATE lv_header lv_body INTO lv_pack IN BYTE MODE.
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING if_algorithm = 'sha1' if_data = lv_pack
      IMPORTING ef_hashxstring = lv_digest ).
    CONCATENATE lv_pack lv_digest INTO lv_pack IN BYTE MODE.
    ASSERT lo_codec->unpack(
      iv_pack = lv_pack iv_repository_id = 'pack-truncated-repository' ) IS INITIAL.

    lv_body = CONV xstring( '3000' ).
    CONCATENATE lv_header lv_body INTO lv_pack IN BYTE MODE.
    CLEAR lv_digest.
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING if_algorithm = 'sha1' if_data = lv_pack
      IMPORTING ef_hashxstring = lv_digest ).
    CONCATENATE lv_pack lv_digest INTO lv_pack IN BYTE MODE.
    ASSERT lo_codec->unpack(
      iv_pack = lv_pack iv_repository_id = 'pack-malformed-repository' ) IS INITIAL.
  ENDMETHOD.

  METHOD rejects_pack_before_ref_update.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_receiver) = NEW zcl_hithub_pack_receiver(
      io_codec = lo_codec io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction ).
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_read TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_pack TYPE xstring.
    DATA lv_digest TYPE xstring.
    DATA lv_last_offset TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_repository_id TYPE string.
    DATA lv_target_oid TYPE string.

    lv_repository_id = 'pack-rejected-ref-repository-000'.
    ls_reference-repository_id = lv_repository_id.
    ls_reference-name = 'refs/heads/main'.
    ls_reference-algorithm = 'sha1'.
    ls_reference-oid = '0000000000000000000000000000000000000001'.
    ASSERT lo_metadata->zif_hithub_metadata_store~save_reference(
      ls_reference ) = 1.

    ls_object-key-repository_id = lv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-type = 'blob'.
    ls_object-payload = cl_abap_codepage=>convert_to( source = 'incoming' ).
    ls_object-size = xstrlen( ls_object-payload ).
    lv_target_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = ls_object-type iv_payload = ls_object-payload ).
    ls_object-key-oid = lv_target_oid.
    APPEND ls_object TO lt_objects.
    lv_pack = lo_codec->repack( lt_objects ).
    lv_last_offset = xstrlen( lv_pack ) - 1.
    lv_byte = lv_pack+lv_last_offset(1).
    lv_byte = lv_byte BIT-XOR CONV xstring( '01' ).
    DATA(lv_body) = lv_pack+0(lv_last_offset).
    CONCATENATE lv_body lv_byte INTO lv_pack IN BYTE MODE.

    ASSERT lo_receiver->receive(
      iv_pack          = lv_pack
      iv_repository_id = lv_repository_id
      iv_ref_name      = ls_reference-name
      iv_target_oid    = lv_target_oid ) = abap_false.
    ls_read = lo_metadata->zif_hithub_metadata_store~read_reference(
      iv_repository_id = lv_repository_id iv_name = ls_reference-name ).
    ASSERT ls_read-oid = ls_reference-oid.
    ASSERT ls_read-version = 1.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_object-key ) = abap_false.
    ASSERT lo_transaction->zif_hithub_transaction~is_active( ) = abap_false.
  ENDMETHOD.

  METHOD rejects_pack_over_limit.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_limits) = NEW zcl_hithub_pack_limits(
      iv_max_pack_size = 1 iv_max_objects = 1 ).
    DATA(lo_receiver) = NEW zcl_hithub_pack_receiver(
      io_codec = lo_codec io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction io_limits = lo_limits ).

    ASSERT lo_receiver->receive(
      iv_pack          = CONV xstring( '5041434B0000000200000000' )
      iv_repository_id = 'pack-limit-repository-000000000'
      iv_ref_name      = 'refs/heads/main'
      iv_target_oid    = '1111111111111111111111111111111111111111' ) =
      abap_false.
    ASSERT lo_transaction->zif_hithub_transaction~is_active( ) = abap_false.
  ENDMETHOD.

  METHOD promotes_before_ref_save.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_metadata) = NEW zcl_hithub_local_meta_store( ).
    DATA(lo_transaction) = NEW zcl_hithub_local_unit_work( ).
    DATA(lo_quarantine) = NEW zcl_hithub_quarantine( lo_store ).
    DATA(lo_event_sink) = NEW lcl_receive_event_sink( ).
    DATA(lo_clock) = NEW lcl_receive_clock( ).
    DATA(lo_context) = NEW zcl_hithub_request_context(
      iv_actor_label = 'actor-1' iv_correlation_id = 'correlation-1' ).
    DATA(lo_receiver) = NEW zcl_hithub_pack_receiver(
      io_codec = lo_codec io_store = lo_store io_metadata = lo_metadata
      io_transaction = lo_transaction io_quarantine = lo_quarantine
      io_event_sink = lo_event_sink io_request_context = lo_context
      io_clock = lo_clock ).
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_repository_id TYPE string.
    DATA lv_target_oid TYPE string.
    DATA lv_pack TYPE xstring.

    lv_repository_id = 'pack-quarantine-repository-0000'.
    ls_object-key-repository_id = lv_repository_id.
    ls_object-key-algorithm = 'sha1'.
    ls_object-type = 'blob'.
    ls_object-payload = cl_abap_codepage=>convert_to( source = 'incoming' ).
    ls_object-size = xstrlen( ls_object-payload ).
    lv_target_oid = zcl_hithub_object_id=>calculate(
      iv_algorithm = 'sha1' iv_type = ls_object-type
      iv_payload = ls_object-payload ).
    ls_object-key-oid = lv_target_oid.
    APPEND ls_object TO lt_objects.
    lv_pack = lo_codec->repack( lt_objects ).

    ASSERT lo_receiver->receive(
      iv_pack = lv_pack iv_repository_id = lv_repository_id
      iv_ref_name = 'refs/tags/incoming'
      iv_target_oid = lv_target_oid ) = abap_true.
    DATA ls_target_key TYPE zif_hithub_object_store=>ty_object_key.
    ls_target_key-repository_id = lv_repository_id.
    ls_target_key-algorithm = 'sha1'.
    ls_target_key-oid = lv_target_oid.
    ASSERT lo_store->zif_hithub_object_store~contains( ls_target_key ) =
      abap_true.
    DATA(ls_event) = lo_event_sink->event( ).
    ASSERT ls_event-action = 'push'.
    ASSERT ls_event-subject_id = lv_repository_id.
    ASSERT ls_event-actor = 'actor-1'.
    ASSERT ls_event-correlation_id = 'correlation-1'.
    ASSERT ls_event-occurred_at = '20260828123456.0000000'.
  ENDMETHOD.

  METHOD unpacks_delta_objects.
    DATA(lo_compression) = NEW lcl_pack_compression( ).
    DATA(lo_codec) = NEW zcl_hithub_pack_codec( lo_compression ).
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lt_unpacked TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA lv_header TYPE xstring.
    DATA lv_base_entry TYPE xstring.
    DATA lv_delta_entry TYPE xstring.
    DATA lv_base TYPE xstring.
    DATA lv_delta TYPE xstring.
    DATA lv_pack_body TYPE xstring.
    DATA lv_digest TYPE xstring.
    DATA lv_pack TYPE xstring.
    DATA lv_f0 TYPE xstring.
    DATA lv_size_06 TYPE xstring.
    DATA lv_size_0b TYPE xstring.
    DATA lv_base_header TYPE xstring.
    DATA lv_delta_header TYPE xstring.
    DATA lv_distance TYPE xstring.

    lv_base = cl_abap_codepage=>convert_to( source = 'abcdef' ).
    lv_delta = CONV xstring( '060990030358595A910303' ).
    lv_f0 = CONV xstring( 'F0' ).
    lv_size_06 = CONV xstring( '06' ).
    lv_size_0b = CONV xstring( '0B' ).
    lv_base_header = CONV xstring( '36' ).
    lv_delta_header = CONV xstring( '6B' ).
    lv_distance = CONV xstring( '09' ).
    CONCATENATE lv_f0 lv_size_06 lv_base
      INTO lv_base_entry IN BYTE MODE.
    CONCATENATE lv_f0 lv_size_0b lv_delta
      INTO lv_delta_entry IN BYTE MODE.
    CONCATENATE lv_base_header lv_base_entry
      lv_delta_header lv_distance lv_delta_entry
      INTO lv_pack_body IN BYTE MODE.
    lv_header = zcl_hithub_pack_header=>build( 2 ).
    CONCATENATE lv_header lv_pack_body INTO lv_pack IN BYTE MODE.
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING if_algorithm = 'sha1' if_data = lv_pack
      IMPORTING ef_hashxstring = lv_digest ).
    CONCATENATE lv_pack lv_digest INTO lv_pack IN BYTE MODE.

    lt_unpacked = lo_codec->unpack(
      iv_pack = lv_pack iv_repository_id = 'pack-delta-repository' ).

    ASSERT lines( lt_unpacked ) = 2.
    READ TABLE lt_unpacked INTO ls_object INDEX 2.
    ASSERT ls_object-type = 'blob'.
    ASSERT ls_object-payload = cl_abap_codepage=>convert_to( source = 'abcXYZdef' ).
  ENDMETHOD.

ENDCLASS.
