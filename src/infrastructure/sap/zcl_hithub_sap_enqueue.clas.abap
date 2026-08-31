CLASS zcl_hithub_sap_enqueue DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_enqueue.

ENDCLASS.

CLASS zcl_hithub_sap_enqueue IMPLEMENTATION.

  METHOD zif_hithub_enqueue~acquire.
    CLEAR rv_acquired.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    CALL FUNCTION 'ENQUEUE_EZHI_REPO'
      EXPORTING
        repository_id  = iv_repository_id
        _scope         = '2'
        _wait          = ' '
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    rv_acquired = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_enqueue~release.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    CALL FUNCTION 'DEQUEUE_EZHI_REPO'
      EXPORTING
        repository_id = iv_repository_id
        _scope        = '2'.
  ENDMETHOD.

ENDCLASS.
