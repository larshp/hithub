CLASS zcl_hithub_sap_enqueue DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_enqueue.

ENDCLASS.

CLASS zcl_hithub_sap_enqueue IMPLEMENTATION.

  METHOD zif_hithub_enqueue~acquire.
    DATA lv_repository_id TYPE zhi_de_char36.

    CLEAR rv_acquired.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    lv_repository_id = iv_repository_id.
    CALL FUNCTION 'ENQUEUE_EZHI_REPO'
      EXPORTING
        repository_id  = lv_repository_id
        _scope         = '2'
        _wait          = ' '
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    rv_acquired = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_enqueue~release.
    DATA lv_repository_id TYPE zhi_de_char36.

    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    lv_repository_id = iv_repository_id.
    CALL FUNCTION 'DEQUEUE_EZHI_REPO'
      EXPORTING
        repository_id = lv_repository_id
        _scope        = '2'.
  ENDMETHOD.

ENDCLASS.
