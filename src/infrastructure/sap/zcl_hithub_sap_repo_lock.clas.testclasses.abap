CLASS lcl_shared_enqueue DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_enqueue.

  PRIVATE SECTION.
    TYPES ty_repositories TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    CLASS-DATA gt_locked TYPE ty_repositories.

ENDCLASS.

CLASS lcl_shared_enqueue IMPLEMENTATION.

  METHOD zif_hithub_enqueue~acquire.
    READ TABLE gt_locked TRANSPORTING NO FIELDS
      WITH KEY table_line = iv_repository_id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND iv_repository_id TO gt_locked.
    rv_acquired = abap_true.
  ENDMETHOD.

  METHOD zif_hithub_enqueue~release.
    DELETE gt_locked WHERE table_line = iv_repository_id.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_sap_repo_lock DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS serializes_two_server_clients FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_sap_repo_lock IMPLEMENTATION.

  METHOD serializes_two_server_clients.
    DATA(lo_enqueue) = NEW lcl_shared_enqueue( ).
    DATA(lo_server_a) = NEW zcl_hithub_sap_repo_lock(
      io_enqueue = lo_enqueue ).
    DATA(lo_server_b) = NEW zcl_hithub_sap_repo_lock(
      io_enqueue = lo_enqueue ).
    DATA(lv_repository_id) = 'sap-lock-repository'.

    ASSERT lo_server_a->zif_hithub_repository_lock~acquire(
      iv_repository_id = lv_repository_id iv_owner = 'server-a'
      iv_timeout_seconds = 0 ) = abap_true.
    ASSERT lo_server_b->zif_hithub_repository_lock~acquire(
      iv_repository_id = lv_repository_id iv_owner = 'server-b'
      iv_timeout_seconds = 0 ) = abap_false.
    ASSERT lo_server_a->zif_hithub_repository_lock~is_held(
      iv_repository_id = lv_repository_id iv_owner = 'server-a' ) = abap_true.
    lo_server_a->zif_hithub_repository_lock~release(
      iv_repository_id = lv_repository_id iv_owner = 'server-a' ).
    ASSERT lo_server_b->zif_hithub_repository_lock~acquire(
      iv_repository_id = lv_repository_id iv_owner = 'server-b'
      iv_timeout_seconds = 0 ) = abap_true.
    lo_server_b->zif_hithub_repository_lock~release(
      iv_repository_id = lv_repository_id iv_owner = 'server-b' ).
  ENDMETHOD.

ENDCLASS.
