CLASS zcl_hithub_changed_files DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_rename_detection_enabled TYPE abap_bool VALUE abap_false.

    TYPES:
      BEGIN OF ty_file,
        path TYPE string,
        oid  TYPE string,
        mode TYPE string,
      END OF ty_file,
      ty_files TYPE STANDARD TABLE OF ty_file WITH DEFAULT KEY,
      BEGIN OF ty_change,
        path    TYPE string,
        status  TYPE string,
        old_oid TYPE string,
        new_oid TYPE string,
      END OF ty_change,
      ty_changes TYPE STANDARD TABLE OF ty_change WITH DEFAULT KEY.

    CLASS-METHODS calculate
      IMPORTING
        it_base TYPE ty_files
        it_head TYPE ty_files
      RETURNING
        VALUE(rt_changes) TYPE ty_changes.
ENDCLASS.

CLASS zcl_hithub_changed_files IMPLEMENTATION.

  METHOD calculate.
    DATA ls_base TYPE ty_file.
    DATA ls_head TYPE ty_file.
    DATA ls_change TYPE ty_change.

    CLEAR rt_changes.
    LOOP AT it_head INTO ls_head.
      READ TABLE it_base WITH KEY path = ls_head-path INTO ls_base.
      IF sy-subrc <> 0.
        CLEAR ls_change.
        ls_change-path = ls_head-path.
        ls_change-status = 'added'.
        ls_change-new_oid = ls_head-oid.
        APPEND ls_change TO rt_changes.
        CONTINUE.
      ENDIF.
      IF ls_base-oid = ls_head-oid AND ls_base-mode = ls_head-mode.
        CONTINUE.
      ENDIF.
      CLEAR ls_change.
      ls_change-path = ls_head-path.
      ls_change-status = 'modified'.
      ls_change-old_oid = ls_base-oid.
      ls_change-new_oid = ls_head-oid.
      APPEND ls_change TO rt_changes.
    ENDLOOP.

    LOOP AT it_base INTO ls_base.
      IF line_exists( it_head[ path = ls_base-path ] ).
        CONTINUE.
      ENDIF.
      CLEAR ls_change.
      ls_change-path = ls_base-path.
      ls_change-status = 'deleted'.
      ls_change-old_oid = ls_base-oid.
      APPEND ls_change TO rt_changes.
    ENDLOOP.

    SORT rt_changes BY path.
  ENDMETHOD.

ENDCLASS.
