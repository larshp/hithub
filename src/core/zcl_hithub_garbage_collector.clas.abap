CLASS zcl_hithub_garbage_collector DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_store                TYPE REF TO zif_hithub_object_store
        io_metadata             TYPE REF TO zif_hithub_metadata_store
        io_gc                   TYPE REF TO zif_hithub_object_gc
        io_roots                TYPE REF TO zif_hithub_gc_roots OPTIONAL
        io_clock                TYPE REF TO zif_hithub_clock OPTIONAL
        iv_grace_period_seconds TYPE int8 DEFAULT 86400.

    METHODS collect
      IMPORTING
        iv_repository_id  TYPE string
        iv_dry_run        TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rv_deleted) TYPE i
      RAISING cx_static_check.

    METHODS report
      IMPORTING
        iv_repository_id     TYPE string
      RETURNING
        VALUE(rt_candidates) TYPE zif_hithub_object_gc=>ty_candidates
      RAISING cx_static_check.

  PRIVATE SECTION.
    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_gc TYPE REF TO zif_hithub_object_gc.
    DATA mo_roots TYPE REF TO zif_hithub_gc_roots.
    DATA mo_clock TYPE REF TO zif_hithub_clock.
    DATA mv_grace_period_seconds TYPE int8.

    METHODS find_candidates
      IMPORTING
        iv_repository_id     TYPE string
      RETURNING
        VALUE(rt_candidates) TYPE zif_hithub_object_gc=>ty_candidates
      RAISING cx_static_check.
ENDCLASS.

CLASS zcl_hithub_garbage_collector IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
    mo_metadata = io_metadata.
    mo_gc = io_gc.
    mo_roots = io_roots.
    mo_clock = io_clock.
    mv_grace_period_seconds = iv_grace_period_seconds.
  ENDMETHOD.

  METHOD find_candidates.
    DATA lt_reachable TYPE zcl_hithub_reachability=>ty_keys.
    DATA lt_protected TYPE zif_hithub_gc_roots=>ty_keys.
    DATA lt_objects TYPE zif_hithub_object_gc=>ty_candidates.
    DATA lt_references TYPE zif_hithub_metadata_store=>ty_references.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_object_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_candidate TYPE zif_hithub_object_gc=>ty_candidate.
    DATA lv_now TYPE timestampl.
    DATA lv_cutoff TYPE timestampl.
    DATA lo_reader TYPE REF TO zcl_hithub_object_reader.
    DATA lo_reachability TYPE REF TO zcl_hithub_reachability.

    CLEAR rt_candidates.
    IF iv_repository_id IS INITIAL OR mo_store IS INITIAL
        OR mo_metadata IS INITIAL OR mo_gc IS INITIAL.
      RETURN.
    ENDIF.
    lo_reader = NEW zcl_hithub_object_reader( mo_store ).
    lo_reachability = NEW zcl_hithub_reachability( lo_reader ).
    IF mv_grace_period_seconds > 0.
      IF mo_clock IS INITIAL.
        GET TIME STAMP FIELD lv_now.
      ELSE.
        lv_now = mo_clock->now( ).
      ENDIF.
      lv_cutoff = cl_abap_tstmp=>subtractsecs(
        tstmp = lv_now secs = mv_grace_period_seconds ).
    ENDIF.
    IF mo_roots IS NOT INITIAL.
      lt_protected = mo_roots->list( iv_repository_id ).
    ENDIF.
    lt_references = mo_metadata->list_references( iv_repository_id ).
    LOOP AT lt_references INTO ls_reference.
      IF ls_reference-oid IS INITIAL OR ls_reference-symbolic_target IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR ls_object_key.
      ls_object_key-repository_id = iv_repository_id.
      ls_object_key-algorithm = ls_reference-algorithm.
      ls_object_key-oid = ls_reference-oid.
      DATA(lt_from_ref) = lo_reachability->walk( ls_object_key ).
      LOOP AT lt_from_ref INTO ls_key.
        IF NOT line_exists( lt_reachable[ repository_id = ls_key-repository_id
          algorithm = ls_key-algorithm oid = ls_key-oid ] ).
          APPEND ls_key TO lt_reachable.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    lt_objects = mo_gc->list( iv_repository_id ).
    LOOP AT lt_objects INTO ls_candidate.
      ls_key = ls_candidate-key.
      IF line_exists( lt_reachable[ repository_id = ls_key-repository_id
          algorithm = ls_key-algorithm oid = ls_key-oid ] ).
        CONTINUE.
      ENDIF.
      IF line_exists( lt_protected[ repository_id = ls_key-repository_id
          algorithm = ls_key-algorithm oid = ls_key-oid ] ).
        CONTINUE.
      ENDIF.
      IF lv_cutoff IS NOT INITIAL
          AND ( ls_candidate-created_at IS INITIAL
            OR ls_candidate-created_at >= lv_cutoff ).
        CONTINUE.
      ENDIF.
      APPEND ls_candidate TO rt_candidates.
    ENDLOOP.
  ENDMETHOD.

  METHOD report.
    rt_candidates = find_candidates( iv_repository_id ).
  ENDMETHOD.

  METHOD collect.
    DATA lt_candidates TYPE zif_hithub_object_gc=>ty_candidates.
    DATA ls_candidate TYPE zif_hithub_object_gc=>ty_candidate.

    CLEAR rv_deleted.
    lt_candidates = find_candidates( iv_repository_id ).
    IF iv_dry_run = abap_true.
      rv_deleted = lines( lt_candidates ).
      RETURN.
    ENDIF.
    LOOP AT lt_candidates INTO ls_candidate.
      IF mo_gc->delete( ls_candidate-key ) = abap_true.
        rv_deleted = rv_deleted + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
