CLASS zcl_hithub_receive_batch DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_store       TYPE REF TO zif_hithub_object_store
        io_metadata    TYPE REF TO zif_hithub_metadata_store
        io_codec       TYPE REF TO zcl_hithub_pack_codec
        io_transaction TYPE REF TO zif_hithub_transaction
        io_quarantine  TYPE REF TO zif_hithub_quarantine OPTIONAL.

    METHODS apply
      IMPORTING
        iv_repository_id TYPE string
        iv_pack          TYPE xstring
        it_commands      TYPE zcl_hithub_receive_request=>ty_commands
      EXPORTING
        et_results       TYPE zcl_hithub_receive_status=>ty_results
        rv_success       TYPE abap_bool
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_current,
        command   TYPE zcl_hithub_receive_request=>ty_command,
        reference TYPE zif_hithub_metadata_store=>ty_reference,
      END OF ty_current,
      ty_currents TYPE STANDARD TABLE OF ty_current WITH DEFAULT KEY.

    DATA mo_store TYPE REF TO zif_hithub_object_store.
    DATA mo_metadata TYPE REF TO zif_hithub_metadata_store.
    DATA mo_codec TYPE REF TO zcl_hithub_pack_codec.
    DATA mo_transaction TYPE REF TO zif_hithub_transaction.
    DATA mo_quarantine TYPE REF TO zif_hithub_quarantine.

ENDCLASS.

CLASS zcl_hithub_receive_batch IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
    mo_metadata = io_metadata.
    mo_codec = io_codec.
    mo_transaction = io_transaction.
    IF io_quarantine IS INITIAL.
      mo_quarantine = NEW zcl_hithub_quarantine( io_store ).
    ELSE.
      mo_quarantine = io_quarantine.
    ENDIF.
  ENDMETHOD.

  METHOD apply.
    CONSTANTS lc_zero_oid TYPE string VALUE
      '0000000000000000000000000000000000000000'.
    DATA ls_command TYPE zcl_hithub_receive_request=>ty_command.
    DATA ls_current TYPE ty_current.
    DATA ls_result TYPE zcl_hithub_receive_status=>ty_result.
    DATA lt_currents TYPE ty_currents.
    DATA lt_objects TYPE zcl_hithub_pack_codec=>ty_objects.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA lv_has_update TYPE abap_bool.
    DATA lv_valid TYPE abap_bool.
    DATA lv_saved_version TYPE int8.

    CLEAR: rv_success, et_results.
    IF mo_store IS INITIAL OR mo_metadata IS INITIAL
        OR mo_codec IS INITIAL OR mo_transaction IS INITIAL
        OR mo_quarantine IS INITIAL OR iv_repository_id IS INITIAL
        OR it_commands IS INITIAL.
      RETURN.
    ENDIF.

    lv_valid = abap_true.
    LOOP AT it_commands INTO ls_command.
      CLEAR: ls_current, ls_result.
      ls_current-command = ls_command.
      ls_current-reference =
        mo_metadata->read_reference(
          iv_repository_id = iv_repository_id
          iv_name          = ls_command-ref_name ).
      ls_result-ref_name = ls_command-ref_name.
      IF zcl_hithub_ref_update_policy=>old_oid_matches(
          io_metadata = mo_metadata iv_repository_id = iv_repository_id
          iv_ref_name = ls_command-ref_name iv_algorithm = 'sha1'
          iv_old_oid = ls_command-old_oid ) = abap_false.
        ls_result-reason = 'stale info'.
        lv_valid = abap_false.
      ELSEIF ls_command-new_oid = lc_zero_oid
          AND ls_current-reference-oid IS INITIAL.
        ls_result-reason = 'reference not found'.
        lv_valid = abap_false.
      ELSEIF ls_command-new_oid <> lc_zero_oid.
        lv_has_update = abap_true.
      ENDIF.
      APPEND ls_current TO lt_currents.
      APPEND ls_result TO et_results.
    ENDLOOP.

    IF lv_has_update = abap_true AND iv_pack IS NOT INITIAL.
      IF zcl_hithub_pack_trailer=>is_valid( iv_pack ) = abap_false.
        lv_valid = abap_false.
      ELSE.
        ls_header = zcl_hithub_pack_header=>parse( iv_pack ).
        IF ls_header-signature IS INITIAL.
          lv_valid = abap_false.
        ELSE.
          lt_objects = mo_codec->unpack(
            iv_pack = iv_pack iv_repository_id = iv_repository_id ).
          IF ls_header-object_count > 0 AND lt_objects IS INITIAL.
            lv_valid = abap_false.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
    IF lv_valid = abap_false.
      LOOP AT et_results ASSIGNING FIELD-SYMBOL(<ls_rejected>).
        IF <ls_rejected>-reason IS INITIAL.
          <ls_rejected>-reason = 'batch rejected'.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    mo_transaction->start( ).
    TRY.
        IF lt_objects IS NOT INITIAL.
          IF mo_quarantine->stage( lt_objects ) <> lines( lt_objects ).
            mo_quarantine->discard( ).
            mo_transaction->rollback( ).
            RETURN.
          ENDIF.
          IF mo_quarantine->promote( ) <> lines( lt_objects ).
            mo_quarantine->discard( ).
            mo_transaction->rollback( ).
            RETURN.
          ENDIF.
        ENDIF.

        LOOP AT lt_currents INTO ls_current.
          IF ls_current-command-new_oid = lc_zero_oid.
            CONTINUE.
          ENDIF.
          CLEAR ls_key.
          ls_key-repository_id = iv_repository_id.
          ls_key-algorithm = 'sha1'.
          ls_key-oid = ls_current-command-new_oid.
          IF zcl_hithub_receive_target=>is_valid_target(
              io_store = mo_store is_key = ls_key
              iv_ref_name = ls_current-command-ref_name ) = abap_false.
            mo_quarantine->discard( ).
            mo_transaction->rollback( ).
            LOOP AT et_results ASSIGNING <ls_rejected>.
              CLEAR <ls_rejected>-ok.
              IF <ls_rejected>-reason IS INITIAL.
                <ls_rejected>-reason = 'invalid target'.
              ENDIF.
            ENDLOOP.
            RETURN.
          ENDIF.
        ENDLOOP.

        LOOP AT lt_currents INTO ls_current.
          READ TABLE et_results ASSIGNING <ls_rejected> INDEX sy-tabix.
          IF ls_current-command-new_oid = lc_zero_oid.
            mo_metadata->delete_reference(
              iv_repository_id    = iv_repository_id
              iv_name             = ls_current-command-ref_name
              iv_expected_version = ls_current-reference-version ).
            <ls_rejected>-ok = abap_true.
          ELSE.
            DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.
            ls_reference-repository_id = iv_repository_id.
            ls_reference-name = ls_current-command-ref_name.
            ls_reference-algorithm = 'sha1'.
            ls_reference-oid = ls_current-command-new_oid.
            lv_saved_version = mo_metadata->save_reference(
              is_reference        = ls_reference
              iv_expected_version = ls_current-reference-version ).
            IF lv_saved_version IS INITIAL.
              mo_quarantine->discard( ).
              mo_transaction->rollback( ).
              LOOP AT et_results ASSIGNING <ls_rejected>.
                CLEAR <ls_rejected>-ok.
                IF <ls_rejected>-reason IS INITIAL.
                  <ls_rejected>-reason = 'batch update failed'.
                ENDIF.
              ENDLOOP.
              RETURN.
            ENDIF.
            <ls_rejected>-ok = abap_true.
          ENDIF.
        ENDLOOP.

        mo_transaction->commit( ).
      CATCH cx_static_check.
        mo_quarantine->discard( ).
        mo_transaction->rollback( ).
        LOOP AT et_results ASSIGNING <ls_rejected>.
          CLEAR <ls_rejected>-ok.
          IF <ls_rejected>-reason IS INITIAL.
            <ls_rejected>-reason = 'batch update failed'.
          ENDIF.
        ENDLOOP.
        RETURN.
    ENDTRY.
    rv_success = abap_true.
  ENDMETHOD.

ENDCLASS.
