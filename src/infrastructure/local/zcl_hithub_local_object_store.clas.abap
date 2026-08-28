CLASS zcl_hithub_local_object_store DEFINITION
  PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_object_store.
    INTERFACES zif_hithub_object_gc.

ENDCLASS.

CLASS zcl_hithub_local_object_store IMPLEMENTATION.

  METHOD zif_hithub_object_gc~list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_object.
    DATA ls_row TYPE zhi_object.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.

    CLEAR rt_keys.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_object INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_key.
      ls_key-repository_id = ls_row-repository_id.
      ls_key-algorithm = ls_row-algorithm.
      ls_key-oid = ls_row-oid.
      APPEND ls_key TO rt_keys.
    ENDLOOP.
    SORT rt_keys BY algorithm oid.
  ENDMETHOD.

  METHOD zif_hithub_object_gc~delete.
    CLEAR rv_deleted.
    IF is_key-repository_id IS INITIAL OR is_key-algorithm IS INITIAL
        OR is_key-oid IS INITIAL.
      RETURN.
    ENDIF.
    DELETE FROM zhi_object
      WHERE repository_id = @is_key-repository_id
        AND algorithm = @is_key-algorithm
        AND oid = @is_key-oid.
    rv_deleted = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_object_store~read.
    DATA ls_row TYPE zhi_object.

    CLEAR rs_object.
    SELECT SINGLE * FROM zhi_object INTO @ls_row
      WHERE repository_id = @is_key-repository_id
        AND algorithm = @is_key-algorithm
        AND oid = @is_key-oid.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rs_object-key-repository_id = ls_row-repository_id.
    rs_object-key-algorithm = ls_row-algorithm.
    rs_object-key-oid = ls_row-oid.
    rs_object-type = ls_row-object_type.
    rs_object-size = ls_row-object_size.
    rs_object-payload = ls_row-payload.
    IF ls_row-object_size > 0.
      rs_object-payload = ls_row-payload(ls_row-object_size).
    ELSE.
      CLEAR rs_object-payload.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_object_store~contains.
    DATA ls_row TYPE zhi_object.

    CLEAR rv_exists.
    SELECT SINGLE * FROM zhi_object INTO @ls_row
      WHERE repository_id = @is_key-repository_id
        AND algorithm = @is_key-algorithm
        AND oid = @is_key-oid.
    IF sy-subrc = 0.
      rv_exists = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_object_store~write.
    DATA ls_row TYPE zhi_object.

    CLEAR rv_created.
    IF is_object-key-repository_id IS INITIAL
        OR is_object-key-algorithm IS INITIAL
        OR is_object-key-oid IS INITIAL.
      RETURN.
    ENDIF.

    ls_row-repository_id = is_object-key-repository_id.
    ls_row-algorithm = is_object-key-algorithm.
    ls_row-oid = is_object-key-oid.
    ls_row-object_type = is_object-type.
    ls_row-object_size = is_object-size.
    ls_row-payload = is_object-payload.
    INSERT zhi_object FROM @ls_row.
    IF sy-subrc = 0.
      rv_created = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_object_store~purge_repository.
    CLEAR rv_purged.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    DELETE FROM zhi_object
      WHERE repository_id = @iv_repository_id.
    rv_purged = abap_true.
  ENDMETHOD.

ENDCLASS.
