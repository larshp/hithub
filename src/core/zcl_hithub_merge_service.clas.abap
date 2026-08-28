CLASS zcl_hithub_merge_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_result,
        success    TYPE abap_bool,
        reason     TYPE string,
        merge_id   TYPE string,
        commit_oid TYPE string,
      END OF ty_result.

    METHODS constructor
      IMPORTING
        io_store TYPE REF TO zif_hithub_object_store
        io_metadata TYPE REF TO zif_hithub_metadata_store
        io_transaction TYPE REF TO zif_hithub_transaction
        io_lock TYPE REF TO zif_hithub_repository_lock
        io_event_sink TYPE REF TO zif_hithub_event_sink OPTIONAL.

    METHODS execute
      IMPORTING
        iv_repository_id TYPE string
        iv_pull_request_id TYPE string
        iv_expected_head_oid TYPE string
        iv_author TYPE string
        iv_committer TYPE string
        iv_message TYPE string
        iv_owner TYPE string
        iv_clean TYPE abap_bool
      RETURNING
        VALUE(rs_result) TYPE ty_result
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    DATA mo_lock TYPE REF TO zif_hithub_repository_lock.
    DATA mo_event_sink TYPE REF TO zif_hithub_event_sink.
ENDCLASS.

CLASS zcl_hithub_merge_service IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
    mo_lock = io_lock.
    mo_event_sink = io_event_sink.
  ENDMETHOD.

  METHOD execute.
    DATA ls_request TYPE zcl_hithub_pr_snapshot=>ty_snapshot.
    DATA ls_target TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_source TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_source_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_source_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_source_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA ls_merge TYPE zcl_hithub_merge_commit=>ty_result.
    DATA ls_merge_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_target_update TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lo_guard TYPE REF TO zcl_hithub_merge_lock.
    DATA lo_persist TYPE REF TO zcl_hithub_merge_persist.
    DATA ls_pr_result TYPE zcl_hithub_pull_requests=>ty_result.
    DATA ls_merge_result TYPE zcl_hithub_merge_result=>ty_result.
    DATA ls_event TYPE zif_hithub_event_sink=>ty_event.
    DATA lv_merge_id TYPE string.

    CLEAR rs_result.
    IF mo_store IS INITIAL OR mo_metadata IS INITIAL
        OR mo_transaction IS INITIAL OR mo_lock IS INITIAL.
      rs_result-reason = 'merge dependencies are incomplete'.
      RETURN.
    ENDIF.
    ls_merge_result = zcl_hithub_merge_result=>read(
      iv_repository_id = iv_repository_id
      iv_pull_request_id = iv_pull_request_id ).
    IF ls_merge_result-commit_oid IS NOT INITIAL.
      rs_result-success = abap_true.
      rs_result-merge_id = ls_merge_result-merge_id.
      rs_result-commit_oid = ls_merge_result-commit_oid.
      RETURN.
    ENDIF.
    ls_request = zcl_hithub_pull_requests=>find(
      iv_repository_id = iv_repository_id iv_id = iv_pull_request_id ).
    IF ls_request-id IS INITIAL.
      rs_result-reason = 'pull request was not found'.
      RETURN.
    ENDIF.
    IF ls_request-state <> zcl_hithub_pull_request_state=>c_open.
      rs_result-reason = 'pull request is not open'.
      RETURN.
    ENDIF.
    IF iv_expected_head_oid IS INITIAL
        OR iv_expected_head_oid <> ls_request-head_oid.
      rs_result-reason = 'merge request head is stale'.
      RETURN.
    ENDIF.

    lo_guard = NEW zcl_hithub_merge_lock(
      io_lock = mo_lock iv_repository_id = iv_repository_id
      iv_owner = iv_owner ).
    IF lo_guard->acquire( ) = abap_false.
      rs_result-reason = 'repository is locked'.
      RETURN.
    ENDIF.
    ls_target = mo_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = ls_request-target_ref ).
    ls_source = mo_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = ls_request-source_ref ).
    IF ls_target-oid IS INITIAL OR ls_source-oid IS INITIAL
        OR ls_target-oid <> ls_request-base_oid
        OR ls_source-oid <> iv_expected_head_oid.
      lo_guard->release( ).
      rs_result-reason = 'merge request references are stale'.
      RETURN.
    ENDIF.

    ls_source_key-repository_id = iv_repository_id.
    ls_source_key-algorithm = ls_source-algorithm.
    ls_source_key-oid = ls_source-oid.
    ls_source_object = mo_store->read( ls_source_key ).
    IF ls_source_object-type <> 'commit'.
      lo_guard->release( ).
      rs_result-reason = 'source head commit was not found'.
      RETURN.
    ENDIF.
    ls_source_commit = zcl_hithub_commit_codec=>decode(
      ls_source_object-payload ).
    IF ls_source_commit-tree IS INITIAL.
      lo_guard->release( ).
      rs_result-reason = 'source head commit is invalid'.
      RETURN.
    ENDIF.
    ls_merge = zcl_hithub_merge_commit=>create(
      iv_tree_oid = ls_source_commit-tree
      iv_target_oid = ls_target-oid iv_source_oid = ls_source-oid
      iv_expected_head_oid = iv_expected_head_oid
      iv_current_head_oid = ls_source-oid iv_author = iv_author
      iv_committer = iv_committer iv_message = iv_message
      iv_clean = iv_clean ).
    IF ls_merge-success = abap_false.
      lo_guard->release( ).
      rs_result-reason = ls_merge-reason.
      RETURN.
    ENDIF.
    ls_merge_object-key-repository_id = iv_repository_id.
    ls_merge_object-key-algorithm = ls_target-algorithm.
    ls_merge_object-key-oid = ls_merge-oid.
    ls_merge_object-type = 'commit'.
    ls_merge_object-size = xstrlen( ls_merge-payload ).
    ls_merge_object-payload = ls_merge-payload.
    ls_target_update = ls_target.
    ls_target_update-oid = ls_merge-oid.
    lo_persist = NEW zcl_hithub_merge_persist(
      io_store = mo_store io_metadata = mo_metadata
      io_transaction = mo_transaction ).
    IF lo_persist->apply(
        is_object = ls_merge_object is_reference = ls_target_update
        iv_expected_version = ls_target-version ) = abap_false.
      lo_guard->release( ).
      rs_result-reason = 'merge object or target update failed'.
      RETURN.
    ENDIF.
    lo_guard->release( ).

    ls_pr_result = zcl_hithub_pull_requests=>transition(
      iv_repository_id = iv_repository_id iv_id = iv_pull_request_id
      iv_state = zcl_hithub_pull_request_state=>c_merged
      iv_expected_version = ls_request-version ).
    IF ls_pr_result-success = abap_false.
      rs_result-reason = 'merged target updated but pull request state failed'.
      RETURN.
    ENDIF.
    lv_merge_id = |merge-{ ls_merge-oid+0(30) }|.
    ls_merge_result-repository_id = iv_repository_id.
    ls_merge_result-pull_request_id = iv_pull_request_id.
    ls_merge_result-merge_id = lv_merge_id.
    ls_merge_result-commit_oid = ls_merge-oid.
    GET TIME STAMP FIELD ls_merge_result-created_at.
    zcl_hithub_merge_result=>save( ls_merge_result ).
    IF mo_event_sink IS NOT INITIAL.
      ls_event-action = 'merge'.
      ls_event-subject_type = 'pull_request'.
      ls_event-subject_id = iv_pull_request_id.
      ls_event-actor = iv_author.
      ls_event-details = |repository={ iv_repository_id } commit={ ls_merge-oid }|.
      mo_event_sink->emit( ls_event ).
    ENDIF.
    rs_result-success = abap_true.
    rs_result-merge_id = lv_merge_id.
    rs_result-commit_oid = ls_merge-oid.
  ENDMETHOD.

ENDCLASS.
