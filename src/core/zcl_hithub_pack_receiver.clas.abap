CLASS zcl_hithub_pack_receiver DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
      io_codec      TYPE REF TO zcl_hithub_pack_codec
      io_store      TYPE REF TO zif_hithub_object_store
      io_metadata   TYPE REF TO zif_hithub_metadata_store
      io_transaction TYPE REF TO zif_hithub_transaction
      io_limits     TYPE REF TO zcl_hithub_pack_limits OPTIONAL
      io_quarantine TYPE REF TO zif_hithub_quarantine OPTIONAL
      io_event_sink TYPE REF TO zif_hithub_event_sink OPTIONAL
      io_request_context TYPE REF TO zif_hithub_request_context OPTIONAL
      io_clock TYPE REF TO zif_hithub_clock OPTIONAL.

    METHODS receive
      IMPORTING
        iv_pack              TYPE xstring
        iv_repository_id    TYPE string
        iv_ref_name         TYPE string
        iv_target_oid       TYPE string
        iv_algorithm        TYPE string DEFAULT 'sha1'
        iv_expected_version TYPE int8 OPTIONAL
      RETURNING
        VALUE(rv_updated) TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_codec TYPE REF TO zcl_hithub_pack_codec.
    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    DATA mo_limits TYPE REF TO zcl_hithub_pack_limits.
    DATA mo_quarantine TYPE REF TO zif_hithub_quarantine.
    DATA mo_event_sink TYPE REF TO zif_hithub_event_sink.
    DATA mo_request_context TYPE REF TO zif_hithub_request_context.
    DATA mo_clock TYPE REF TO zif_hithub_clock.

ENDCLASS.

CLASS zcl_hithub_pack_receiver IMPLEMENTATION.

  METHOD constructor.
    mo_codec = io_codec.
    mo_store = io_store.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
    IF io_limits IS INITIAL.
      mo_limits = NEW zcl_hithub_pack_limits( ).
    ELSE.
      mo_limits = io_limits.
    ENDIF.
    IF io_quarantine IS INITIAL.
      mo_quarantine = NEW zcl_hithub_quarantine( io_store ).
    ELSE.
      mo_quarantine = io_quarantine.
    ENDIF.
    mo_event_sink = io_event_sink.
    mo_request_context = io_request_context.
    mo_clock = io_clock.
  ENDMETHOD.

  METHOD receive.
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_version TYPE int8.

    CLEAR rv_updated.
    IF mo_codec IS INITIAL OR mo_store IS INITIAL
        OR mo_metadata IS INITIAL OR mo_transaction IS INITIAL.
      RETURN.
    ENDIF.
    IF zcl_hithub_ref_validator=>is_valid( iv_ref_name ) = abap_false
        OR zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = iv_algorithm iv_oid = iv_target_oid ) = abap_false.
      RETURN.
    ENDIF.
    DATA(ls_header) = zcl_hithub_pack_header=>parse( iv_pack ).
    IF mo_limits->is_allowed(
        iv_pack_size = xstrlen( iv_pack )
        iv_objects = ls_header-object_count ) = abap_false.
      RETURN.
    ENDIF.

    lt_objects = mo_codec->unpack(
      iv_pack = iv_pack
      iv_repository_id = iv_repository_id
      iv_algorithm = iv_algorithm ).
    IF lt_objects IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE lt_objects INTO ls_object
      WITH KEY key-repository_id = iv_repository_id
        key-algorithm = iv_algorithm key-oid = iv_target_oid.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    mo_transaction->start( ).
    IF mo_quarantine->stage( lt_objects ) <> lines( lt_objects ).
      mo_quarantine->discard( ).
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.
    mo_quarantine->promote( ).
    DATA ls_target_key TYPE zif_hithub_object_store=>ty_object_key.
    ls_target_key-repository_id = iv_repository_id.
    ls_target_key-algorithm = iv_algorithm.
    ls_target_key-oid = iv_target_oid.
    IF mo_store->contains( ls_target_key ) = abap_false.
      mo_quarantine->discard( ).
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.

    ls_reference-repository_id = iv_repository_id.
    ls_reference-name = iv_ref_name.
    ls_reference-algorithm = iv_algorithm.
    ls_reference-oid = iv_target_oid.
    lv_version = mo_metadata->save_reference(
      is_reference = ls_reference
      iv_expected_version = iv_expected_version ).
    IF lv_version IS INITIAL.
      mo_quarantine->discard( ).
      mo_transaction->rollback( ).
      RETURN.
    ENDIF.

    mo_transaction->commit( ).
    IF mo_event_sink IS NOT INITIAL.
      DATA ls_event TYPE zif_hithub_event_sink=>ty_event.
      ls_event-action = 'push'.
      ls_event-subject_type = 'repository'.
      ls_event-subject_id = iv_repository_id.
      ls_event-details = 'ref=' && iv_ref_name && ' target=' && iv_target_oid.
      IF mo_request_context IS NOT INITIAL.
        ls_event-actor = mo_request_context->actor_label( ).
        ls_event-correlation_id = mo_request_context->correlation_id( ).
      ENDIF.
      IF mo_clock IS NOT INITIAL.
        ls_event-occurred_at = mo_clock->now( ).
      ENDIF.
      mo_event_sink->emit( ls_event ).
    ENDIF.
    rv_updated = abap_true.
  ENDMETHOD.

ENDCLASS.
