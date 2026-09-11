CLASS zcl_hithub_quarantine DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_quarantine.
    INTERFACES zif_hithub_gc_roots.

    METHODS constructor
      IMPORTING
        io_store TYPE REF TO zif_hithub_object_store.

  PRIVATE SECTION.
    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mt_objects TYPE zif_hithub_quarantine=>ty_objects.

ENDCLASS.

CLASS zcl_hithub_quarantine IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~stage.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    CLEAR rv_staged.
    LOOP AT it_objects INTO ls_object.
      IF ls_object-key-repository_id IS INITIAL
          OR ls_object-key-algorithm IS INITIAL
          OR ls_object-key-oid IS INITIAL.
        CONTINUE.
      ENDIF.
      READ TABLE mt_objects TRANSPORTING NO FIELDS
        WITH KEY key-repository_id = ls_object-key-repository_id
          key-algorithm = ls_object-key-algorithm
          key-oid = ls_object-key-oid.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      APPEND ls_object TO mt_objects.
      rv_staged = rv_staged + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~promote.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    CLEAR rv_promoted.
    IF mo_store IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT mt_objects INTO ls_object.
      IF mo_store->write( ls_object ) = abap_true.
        rv_promoted = rv_promoted + 1.
      ENDIF.
    ENDLOOP.
    CLEAR mt_objects.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~discard.
    CLEAR mt_objects.
  ENDMETHOD.

  METHOD zif_hithub_quarantine~count.
    rv_count = lines( mt_objects ).
  ENDMETHOD.

  METHOD zif_hithub_gc_roots~list.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.

    CLEAR rt_keys.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT mt_objects INTO ls_object
        WHERE key-repository_id = iv_repository_id.
      APPEND ls_object-key TO rt_keys.
    ENDLOOP.
    SORT rt_keys BY algorithm oid.
  ENDMETHOD.

ENDCLASS.
