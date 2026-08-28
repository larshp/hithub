CLASS zcl_hithub_patch_summary DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_summary,
        added    TYPE i,
        modified TYPE i,
        deleted  TYPE i,
        total    TYPE i,
      END OF ty_summary.

    CLASS-METHODS generate
      IMPORTING
        it_changes TYPE zcl_hithub_changed_files=>ty_changes
      RETURNING
        VALUE(rs_summary) TYPE ty_summary.
ENDCLASS.

CLASS zcl_hithub_patch_summary IMPLEMENTATION.

  METHOD generate.
    DATA ls_change TYPE zcl_hithub_changed_files=>ty_change.

    CLEAR rs_summary.
    LOOP AT it_changes INTO ls_change.
      rs_summary-total = rs_summary-total + 1.
      CASE ls_change-status.
        WHEN 'added'.
          rs_summary-added = rs_summary-added + 1.
        WHEN 'modified'.
          rs_summary-modified = rs_summary-modified + 1.
        WHEN 'deleted'.
          rs_summary-deleted = rs_summary-deleted + 1.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
