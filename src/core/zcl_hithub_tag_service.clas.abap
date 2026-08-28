CLASS zcl_hithub_tag_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_result.
    TYPES   success TYPE abap_bool.
    TYPES   reason TYPE string.
    TYPES   reference TYPE zif_hithub_metadata_store=>ty_reference.
    TYPES END OF ty_result.
    METHODS constructor
      IMPORTING io_metadata TYPE REF TO zif_hithub_metadata_store
                io_transaction TYPE REF TO zif_hithub_transaction.
    METHODS list IMPORTING iv_repository_id TYPE string
      RETURNING VALUE(rt_references) TYPE zif_hithub_metadata_store=>ty_references
      RAISING cx_static_check.
    METHODS find IMPORTING iv_repository_id TYPE string iv_name TYPE string
      RETURNING VALUE(rs_reference) TYPE zif_hithub_metadata_store=>ty_reference
      RAISING cx_static_check.
    METHODS create
      IMPORTING iv_repository_id TYPE string iv_name TYPE string
                iv_oid TYPE string iv_algorithm TYPE string DEFAULT 'sha1'
      RETURNING VALUE(rs_result) TYPE ty_result RAISING cx_static_check.
    METHODS update
      IMPORTING iv_repository_id TYPE string iv_name TYPE string
                iv_oid TYPE string iv_expected_version TYPE int8
      RETURNING VALUE(rs_result) TYPE ty_result RAISING cx_static_check.
    METHODS delete
      IMPORTING iv_repository_id TYPE string iv_name TYPE string
                iv_expected_version TYPE int8
      RETURNING VALUE(rs_result) TYPE ty_result RAISING cx_static_check.
  PRIVATE SECTION.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    CLASS-METHODS normalize IMPORTING iv_name TYPE string
      RETURNING VALUE(rv_name) TYPE string.
ENDCLASS.

CLASS zcl_hithub_tag_service IMPLEMENTATION.

  METHOD constructor.
    mo_metadata = io_metadata.
    mo_transaction = io_transaction.
  ENDMETHOD.

  METHOD normalize.
    rv_name = iv_name.
    IF rv_name NP 'refs/tags/*'.
      rv_name = |refs/tags/{ rv_name }|.
    ENDIF.
    IF rv_name NP 'refs/tags/*'
        OR zcl_hithub_ref_validator=>is_valid( rv_name ) = abap_false.
      CLEAR rv_name.
    ENDIF.
  ENDMETHOD.

  METHOD list.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    IF mo_metadata IS INITIAL OR iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT mo_metadata->list_references( iv_repository_id )
        INTO ls_reference.
      IF ls_reference-name CP 'refs/tags/*'
          AND zcl_hithub_ref_validator=>is_valid( ls_reference-name ) =
            abap_true.
        APPEND ls_reference TO rt_references.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD find.
    DATA(lv_name) = normalize( iv_name ).
    IF mo_metadata IS INITIAL OR iv_repository_id IS INITIAL
        OR lv_name IS INITIAL.
      RETURN.
    ENDIF.
    rs_reference = mo_metadata->read_reference(
      iv_repository_id = iv_repository_id iv_name = lv_name ).
    IF rs_reference-name IS INITIAL OR rs_reference-name NP 'refs/tags/*'.
      CLEAR rs_reference.
    ENDIF.
  ENDMETHOD.

  METHOD create.
    DATA(lv_name) = normalize( iv_name ).
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_version TYPE int8.
    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_transaction IS INITIAL
        OR iv_repository_id IS INITIAL OR lv_name IS INITIAL
        OR zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = iv_algorithm iv_oid = iv_oid ) = abap_false.
      rs_result-reason = 'tag input is invalid'.
      RETURN.
    ENDIF.
    DATA(ls_existing) = find(
      iv_repository_id = iv_repository_id iv_name = lv_name ).
    IF ls_existing-name IS NOT INITIAL.
      rs_result-reason = 'tag already exists'.
      RETURN.
    ENDIF.
    ls_reference-repository_id = iv_repository_id.
    ls_reference-name = lv_name.
    ls_reference-algorithm = iv_algorithm.
    ls_reference-oid = iv_oid.
    TRY.
        mo_transaction->start( ).
        lv_version = mo_metadata->create_reference( ls_reference ).
        IF lv_version IS INITIAL.
          mo_transaction->rollback( ).
          rs_result-reason = 'tag already exists'.
          RETURN.
        ENDIF.
        mo_transaction->commit( ).
      CATCH cx_root.
        mo_transaction->rollback( ).
        rs_result-reason = 'tag could not be persisted'.
        RETURN.
    ENDTRY.
    ls_reference-version = lv_version.
    rs_result-success = abap_true.
    rs_result-reference = ls_reference.
  ENDMETHOD.

  METHOD update.
    DATA(lv_name) = normalize( iv_name ).
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA lv_version TYPE int8.
    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_transaction IS INITIAL
        OR iv_repository_id IS INITIAL OR lv_name IS INITIAL
        OR iv_expected_version IS INITIAL
        OR zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha1' iv_oid = iv_oid ) = abap_false.
      rs_result-reason = 'tag input is invalid'.
      RETURN.
    ENDIF.
    ls_reference = find(
      iv_repository_id = iv_repository_id iv_name = lv_name ).
    IF ls_reference-name IS INITIAL.
      rs_result-reason = 'tag was not found'.
      RETURN.
    ENDIF.
    ls_reference-oid = iv_oid.
    TRY.
        mo_transaction->start( ).
        lv_version = mo_metadata->save_reference(
          is_reference = ls_reference
          iv_expected_version = iv_expected_version ).
        IF lv_version IS INITIAL.
          mo_transaction->rollback( ).
          rs_result-reason = 'tag version is stale'.
          RETURN.
        ENDIF.
        mo_transaction->commit( ).
      CATCH cx_root.
        mo_transaction->rollback( ).
        rs_result-reason = 'tag could not be persisted'.
        RETURN.
    ENDTRY.
    ls_reference-version = lv_version.
    rs_result-success = abap_true.
    rs_result-reference = ls_reference.
  ENDMETHOD.

  METHOD delete.
    DATA(lv_name) = normalize( iv_name ).
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
    DATA ls_after TYPE zif_hithub_metadata_store=>ty_reference.
    CLEAR rs_result.
    IF mo_metadata IS INITIAL OR mo_transaction IS INITIAL
        OR iv_repository_id IS INITIAL OR lv_name IS INITIAL
        OR iv_expected_version IS INITIAL.
      rs_result-reason = 'tag input is invalid'.
      RETURN.
    ENDIF.
    ls_reference = find(
      iv_repository_id = iv_repository_id iv_name = lv_name ).
    IF ls_reference-name IS INITIAL.
      rs_result-reason = 'tag was not found'.
      RETURN.
    ENDIF.
    IF ls_reference-version <> iv_expected_version.
      rs_result-reason = 'tag version is stale'.
      RETURN.
    ENDIF.
    TRY.
        mo_transaction->start( ).
        mo_metadata->delete_reference(
          iv_repository_id = iv_repository_id iv_name = lv_name
          iv_expected_version = iv_expected_version ).
        ls_after = mo_metadata->read_reference(
          iv_repository_id = iv_repository_id iv_name = lv_name ).
        IF ls_after-name IS NOT INITIAL.
          mo_transaction->rollback( ).
          rs_result-reason = 'tag could not be deleted'.
          RETURN.
        ENDIF.
        mo_transaction->commit( ).
      CATCH cx_root.
        mo_transaction->rollback( ).
        rs_result-reason = 'tag could not be deleted'.
        RETURN.
    ENDTRY.
    rs_result-success = abap_true.
  ENDMETHOD.

ENDCLASS.
