CLASS zcl_hithub_local_meta_store DEFINITION
  PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_metadata_store.

ENDCLASS.

CLASS zcl_hithub_local_meta_store IMPLEMENTATION.

  METHOD zif_hithub_metadata_store~read_repository.
    DATA ls_row TYPE zhi_repository.

    CLEAR rs_repository.
    SELECT SINGLE * FROM zhi_repository INTO @ls_row
      WHERE id = @iv_id.
    IF sy-subrc <> 0 OR ls_row-deleted = abap_true.
      RETURN.
    ENDIF.

    rs_repository-id = ls_row-id.
    rs_repository-name = ls_row-name.
    rs_repository-description = ls_row-description.
    rs_repository-default_branch = ls_row-default_branch.
    rs_repository-version = ls_row-version.
    IF ls_row-deleted = 'X'.
      rs_repository-deleted = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~read_repository_any.
    DATA ls_row TYPE zhi_repository.

    CLEAR rs_repository.
    SELECT SINGLE * FROM zhi_repository INTO @ls_row
      WHERE id = @iv_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rs_repository-id = ls_row-id.
    rs_repository-name = ls_row-name.
    rs_repository-description = ls_row-description.
    rs_repository-default_branch = ls_row-default_branch.
    rs_repository-version = ls_row-version.
    IF ls_row-deleted = 'X'.
      rs_repository-deleted = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~list_repositories.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_repository WITH DEFAULT KEY.
    DATA ls_row TYPE zhi_repository.
    DATA ls_repository LIKE LINE OF rt_repositories.

    CLEAR rt_repositories.
    SELECT * FROM zhi_repository INTO TABLE @lt_rows ORDER BY name.
    LOOP AT lt_rows INTO ls_row.
      IF iv_include_deleted <> abap_true.
        CHECK ls_row-deleted <> 'X'.
      ENDIF.
      CLEAR ls_repository.
      ls_repository-id = ls_row-id.
      ls_repository-name = ls_row-name.
      ls_repository-description = ls_row-description.
      ls_repository-default_branch = ls_row-default_branch.
      ls_repository-version = ls_row-version.
      IF ls_row-deleted = 'X'.
        ls_repository-deleted = abap_true.
      ENDIF.
      APPEND ls_repository TO rt_repositories.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~save_repository.
    DATA ls_row TYPE zhi_repository.

    ls_row-id = is_repository-id.
    ls_row-name = is_repository-name.
    ls_row-description = is_repository-description.
    ls_row-default_branch = is_repository-default_branch.
    ls_row-version = is_repository-version.
    IF is_repository-deleted = abap_true.
      ls_row-deleted = 'X'.
    ENDIF.
    MODIFY zhi_repository FROM @ls_row.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~update_repository.
    DATA ls_current TYPE zhi_repository.
    DATA ls_row TYPE zhi_repository.

    CLEAR rv_version.
    IF iv_expected_version IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_repository INTO @ls_current
      WHERE id = @is_repository-id.
    IF sy-subrc <> 0 OR ls_current-version <> iv_expected_version.
      RETURN.
    ENDIF.
    ls_row = ls_current.
    ls_row-description = is_repository-description.
    ls_row-default_branch = is_repository-default_branch.
    ls_row-deleted = is_repository-deleted.
    ls_row-version = ls_current-version + 1.
    MODIFY zhi_repository FROM @ls_row.
    IF sy-subrc = 0.
      rv_version = ls_row-version.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~purge_repository.
    DATA ls_current TYPE zhi_repository.

    CLEAR rv_purged.
    IF iv_repository_id IS INITIAL OR iv_expected_version IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_repository INTO @ls_current
      WHERE id = @iv_repository_id.
    IF sy-subrc <> 0 OR ls_current-deleted <> 'X'
        OR ls_current-version <> iv_expected_version.
      RETURN.
    ENDIF.
    DELETE FROM zhi_reference
      WHERE repository_id = @iv_repository_id.
    DELETE FROM zhi_repository
      WHERE id = @iv_repository_id.
    rv_purged = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~read_idempotency.
    DATA ls_row TYPE zhi_idempotency.
    CLEAR rv_subject_id.
    SELECT SINGLE * FROM zhi_idempotency INTO @ls_row
      WHERE actor = @iv_actor AND idempotency_key = @iv_key.
    IF sy-subrc = 0.
      rv_subject_id = ls_row-subject_id.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~save_idempotency.
    DATA ls_row TYPE zhi_idempotency.
    CLEAR rv_saved.
    IF iv_actor IS INITIAL OR iv_key IS INITIAL OR iv_subject_id IS INITIAL.
      RETURN.
    ENDIF.
    ls_row-actor = iv_actor.
    ls_row-idempotency_key = iv_key.
    ls_row-subject_id = iv_subject_id.
    INSERT zhi_idempotency FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~list_references.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_reference WITH DEFAULT KEY.
    DATA ls_row TYPE zhi_reference.
    DATA ls_reference LIKE LINE OF rt_references.

    CLEAR rt_references.
    SELECT * FROM zhi_reference INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id
      ORDER BY ref_name.
    LOOP AT lt_rows INTO ls_row.
      CLEAR ls_reference.
      ls_reference-repository_id = ls_row-repository_id.
      ls_reference-name = ls_row-ref_name.
      ls_reference-algorithm = ls_row-algorithm.
      ls_reference-oid = ls_row-oid.
      ls_reference-symbolic_target = ls_row-symbolic_target.
      ls_reference-version = ls_row-version.
      APPEND ls_reference TO rt_references.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~read_reference.
    DATA ls_row TYPE zhi_reference.

    CLEAR rs_reference.
    SELECT SINGLE * FROM zhi_reference INTO @ls_row
      WHERE repository_id = @iv_repository_id
        AND ref_name = @iv_name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rs_reference-repository_id = ls_row-repository_id.
    rs_reference-name = ls_row-ref_name.
    rs_reference-algorithm = ls_row-algorithm.
    rs_reference-oid = ls_row-oid.
    rs_reference-symbolic_target = ls_row-symbolic_target.
    rs_reference-version = ls_row-version.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~save_reference.
    DATA ls_row TYPE zhi_reference.
    DATA ls_current TYPE zhi_reference.

    SELECT SINGLE * FROM zhi_reference INTO @ls_current
      WHERE repository_id = @is_reference-repository_id
        AND ref_name = @is_reference-name.
    IF sy-subrc = 0.
      IF iv_expected_version IS NOT INITIAL
          AND ls_current-version <> iv_expected_version.
        CLEAR rv_version.
        RETURN.
      ENDIF.
      ls_row-version = ls_current-version + 1.
    ELSE.
      IF iv_expected_version IS NOT INITIAL.
        CLEAR rv_version.
        RETURN.
      ENDIF.
      ls_row-version = 1.
    ENDIF.

    ls_row-repository_id = is_reference-repository_id.
    ls_row-ref_name = is_reference-name.
    ls_row-algorithm = is_reference-algorithm.
    ls_row-oid = is_reference-oid.
    ls_row-symbolic_target = is_reference-symbolic_target.
    MODIFY zhi_reference FROM @ls_row.
    IF sy-subrc = 0.
      rv_version = ls_row-version.
    ELSE.
      CLEAR rv_version.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~create_reference.
    DATA ls_current TYPE zhi_reference.
    DATA ls_row TYPE zhi_reference.

    CLEAR rv_version.
    IF is_reference-repository_id IS INITIAL
        OR is_reference-name IS INITIAL
        OR is_reference-algorithm IS INITIAL
        OR is_reference-oid IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_reference INTO @ls_current
      WHERE repository_id = @is_reference-repository_id
        AND ref_name = @is_reference-name.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = is_reference-repository_id.
    ls_row-ref_name = is_reference-name.
    ls_row-algorithm = is_reference-algorithm.
    ls_row-oid = is_reference-oid.
    ls_row-symbolic_target = is_reference-symbolic_target.
    ls_row-version = 1.
    INSERT zhi_reference FROM @ls_row.
    IF sy-subrc = 0.
      rv_version = 1.
    ENDIF.
  ENDMETHOD.

  METHOD zif_hithub_metadata_store~delete_reference.
    DATA ls_current TYPE zhi_reference.

    SELECT SINGLE * FROM zhi_reference INTO @ls_current
      WHERE repository_id = @iv_repository_id
        AND ref_name = @iv_name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF iv_expected_version IS NOT INITIAL
        AND ls_current-version <> iv_expected_version.
      RETURN.
    ENDIF.
    DELETE FROM zhi_reference
      WHERE repository_id = @iv_repository_id
        AND ref_name = @iv_name.
  ENDMETHOD.

ENDCLASS.
