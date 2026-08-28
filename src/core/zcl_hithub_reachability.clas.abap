CLASS zcl_hithub_reachability DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_keys TYPE STANDARD TABLE OF zif_hithub_object_store=>ty_object_key
      WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        io_reader TYPE REF TO zcl_hithub_object_reader.

    METHODS walk
      IMPORTING
        is_start TYPE zif_hithub_object_store=>ty_object_key
      RETURNING
        VALUE(rt_keys) TYPE ty_keys
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_reader TYPE REF TO zcl_hithub_object_reader.

ENDCLASS.

CLASS zcl_hithub_reachability IMPLEMENTATION.

  METHOD constructor.
    mo_reader = io_reader.
  ENDMETHOD.

  METHOD walk.
    DATA lt_queue TYPE ty_keys.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_child TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_commit TYPE zcl_hithub_commit_codec=>ty_commit.
    DATA lt_entries TYPE zcl_hithub_tree_codec=>ty_entries.
    DATA ls_entry TYPE zcl_hithub_tree_codec=>ty_entry.
    DATA lv_index TYPE i.
    DATA lv_oid TYPE string.

    CLEAR rt_keys.
    IF mo_reader IS INITIAL OR is_start-oid IS INITIAL.
      RETURN.
    ENDIF.
    APPEND is_start TO lt_queue.
    APPEND is_start TO rt_keys.
    lv_index = 1.

    WHILE lv_index <= lines( lt_queue ).
      READ TABLE lt_queue INTO ls_key INDEX lv_index.
      lv_index = lv_index + 1.
      ls_object = mo_reader->read( ls_key ).
      IF ls_object-key-oid IS INITIAL.
        CONTINUE.
      ENDIF.

      IF ls_object-type = 'commit'.
        ls_commit = zcl_hithub_commit_codec=>decode( ls_object-payload ).
        IF ls_commit-tree IS NOT INITIAL.
          CLEAR ls_child.
          ls_child-repository_id = ls_key-repository_id.
          ls_child-algorithm = ls_key-algorithm.
          ls_child-oid = ls_commit-tree.
          READ TABLE rt_keys WITH KEY repository_id = ls_child-repository_id
            algorithm = ls_child-algorithm oid = ls_child-oid TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            APPEND ls_child TO rt_keys.
            APPEND ls_child TO lt_queue.
          ENDIF.
        ENDIF.
        LOOP AT ls_commit-parents INTO lv_oid.
          CLEAR ls_child.
          ls_child-repository_id = ls_key-repository_id.
          ls_child-algorithm = ls_key-algorithm.
          ls_child-oid = lv_oid.
          READ TABLE rt_keys WITH KEY repository_id = ls_child-repository_id
            algorithm = ls_child-algorithm oid = ls_child-oid TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            APPEND ls_child TO rt_keys.
            APPEND ls_child TO lt_queue.
          ENDIF.
        ENDLOOP.
      ELSEIF ls_object-type = 'tree'.
        lt_entries = zcl_hithub_tree_codec=>decode( ls_object-payload ).
        LOOP AT lt_entries INTO ls_entry.
          CLEAR ls_child.
          ls_child-repository_id = ls_key-repository_id.
          ls_child-algorithm = ls_key-algorithm.
          ls_child-oid = ls_entry-oid.
          IF ls_entry-mode = '040000'.
            ls_child-oid = ls_entry-oid.
          ENDIF.
          READ TABLE rt_keys WITH KEY repository_id = ls_child-repository_id
            algorithm = ls_child-algorithm oid = ls_child-oid TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            APPEND ls_child TO rt_keys.
            APPEND ls_child TO lt_queue.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
