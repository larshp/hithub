CLASS ltcl_changed_files DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS reports_file_changes FOR TESTING RAISING cx_static_check.
    METHODS omits_unchanged_files FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_changed_files IMPLEMENTATION.

  METHOD reports_file_changes.
    DATA lt_base TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_head TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_changes TYPE zcl_hithub_changed_files=>ty_changes.
    DATA ls_change TYPE zcl_hithub_changed_files=>ty_change.
    lt_base = VALUE #(
      ( path = 'added.txt' oid = 'old-added' )
      ( path = 'deleted.txt' oid = 'old-deleted' )
      ( path = 'modified.txt' oid = 'old-modified' )
      ( path = 'same.txt' oid = 'same' mode = '100644' ) ).
    lt_head = VALUE #(
      ( path = 'added.txt' oid = 'new-added' )
      ( path = 'modified.txt' oid = 'new-modified' )
      ( path = 'same.txt' oid = 'same' mode = '100644' )
      ( path = 'new.txt' oid = 'new-file' ) ).

    lt_changes = zcl_hithub_changed_files=>calculate(
      it_base = lt_base it_head = lt_head ).
    ASSERT zcl_hithub_changed_files=>c_rename_detection_enabled = abap_false.
    ASSERT lines( lt_changes ) = 4.

    READ TABLE lt_changes WITH KEY path = 'added.txt' INTO ls_change.
    ASSERT sy-subrc = 0.
    ASSERT ls_change-status = 'modified'.
    READ TABLE lt_changes WITH KEY path = 'deleted.txt' INTO ls_change.
    ASSERT sy-subrc = 0.
    ASSERT ls_change-status = 'deleted'.
    READ TABLE lt_changes WITH KEY path = 'new.txt' INTO ls_change.
    ASSERT sy-subrc = 0.
    ASSERT ls_change-status = 'added'.
  ENDMETHOD.

  METHOD omits_unchanged_files.
    DATA lt_base TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_head TYPE zcl_hithub_changed_files=>ty_files.
    DATA lt_changes TYPE zcl_hithub_changed_files=>ty_changes.
    lt_base = VALUE #( ( path = 'same.txt' oid = 'same' mode = '100644' ) ).
    lt_head = VALUE #( ( path = 'same.txt' oid = 'same' mode = '100644' ) ).

    lt_changes = zcl_hithub_changed_files=>calculate(
      it_base = lt_base it_head = lt_head ).
    ASSERT lines( lt_changes ) = 0.
  ENDMETHOD.

ENDCLASS.
