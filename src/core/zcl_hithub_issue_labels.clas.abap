CLASS zcl_hithub_issue_labels DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_labels TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLASS-METHODS add
      IMPORTING
        iv_repository_id TYPE string
        iv_issue_id      TYPE string
        iv_label         TYPE string
      RETURNING
        VALUE(rv_saved) TYPE abap_bool.

    CLASS-METHODS remove
      IMPORTING
        iv_repository_id TYPE string
        iv_issue_id      TYPE string
        iv_label         TYPE string
      RETURNING
        VALUE(rv_removed) TYPE abap_bool.

    CLASS-METHODS list
      IMPORTING
        iv_repository_id TYPE string
        iv_issue_id      TYPE string
      RETURNING
        VALUE(rt_labels) TYPE ty_labels.
ENDCLASS.

CLASS zcl_hithub_issue_labels IMPLEMENTATION.

  METHOD add.
    DATA ls_row TYPE zhi_issue_label.
    DATA ls_existing TYPE zhi_issue_label.

    CLEAR rv_saved.
    IF iv_repository_id IS INITIAL OR iv_issue_id IS INITIAL
        OR iv_label IS INITIAL OR strlen( iv_label ) > 100.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue_label INTO @ls_existing
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id
        AND label = @iv_label.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    ls_row-repository_id = iv_repository_id.
    ls_row-issue_id = iv_issue_id.
    ls_row-label = iv_label.
    INSERT zhi_issue_label FROM @ls_row.
    rv_saved = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD remove.
    DATA ls_existing TYPE zhi_issue_label.

    CLEAR rv_removed.
    IF iv_repository_id IS INITIAL OR iv_issue_id IS INITIAL
        OR iv_label IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM zhi_issue_label INTO @ls_existing
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id
        AND label = @iv_label.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DELETE FROM zhi_issue_label
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id
        AND label = @iv_label.
    rv_removed = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD list.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_issue_label.
    DATA ls_row TYPE zhi_issue_label.

    CLEAR rt_labels.
    IF iv_repository_id IS INITIAL OR iv_issue_id IS INITIAL.
      RETURN.
    ENDIF.
    SELECT * FROM zhi_issue_label INTO TABLE @lt_rows
      WHERE repository_id = @iv_repository_id
        AND issue_id = @iv_issue_id.
    LOOP AT lt_rows INTO ls_row.
      APPEND ls_row-label TO rt_labels.
    ENDLOOP.
    SORT rt_labels.
  ENDMETHOD.

ENDCLASS.
