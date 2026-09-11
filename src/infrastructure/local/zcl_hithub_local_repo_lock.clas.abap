CLASS zcl_hithub_local_repo_lock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_repository_lock.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_lock,
        repository_id TYPE string,
        owner         TYPE string,
      END OF ty_lock,
      ty_locks TYPE HASHED TABLE OF ty_lock WITH UNIQUE KEY repository_id.
    CLASS-DATA gt_locks TYPE ty_locks.
ENDCLASS.

CLASS zcl_hithub_local_repo_lock IMPLEMENTATION.

  METHOD zif_hithub_repository_lock~acquire.
    DATA ls_lock TYPE ty_lock.
    CLEAR rv_acquired.
    IF iv_repository_id IS INITIAL OR iv_owner IS INITIAL
        OR iv_timeout_seconds < 0.
      RETURN.
    ENDIF.
    READ TABLE gt_locks WITH TABLE KEY repository_id = iv_repository_id
      INTO ls_lock.
    IF sy-subrc = 0.
      rv_acquired = xsdbool( ls_lock-owner = iv_owner ).
      RETURN.
    ENDIF.
    ls_lock-repository_id = iv_repository_id.
    ls_lock-owner = iv_owner.
    INSERT ls_lock INTO TABLE gt_locks.
    rv_acquired = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~release.
    DATA ls_lock TYPE ty_lock.
    READ TABLE gt_locks WITH TABLE KEY repository_id = iv_repository_id
      INTO ls_lock.
    IF sy-subrc = 0 AND ls_lock-owner = iv_owner.
      DELETE TABLE gt_locks WITH TABLE KEY repository_id = iv_repository_id.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_repository_lock~is_held.
    DATA ls_lock TYPE ty_lock.
    CLEAR rv_held.
    READ TABLE gt_locks WITH TABLE KEY repository_id = iv_repository_id
      INTO ls_lock.
    IF sy-subrc = 0.
      rv_held = xsdbool( ls_lock-owner = iv_owner ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
