CLASS zcl_hithub_ref_visibility DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS filter
      IMPORTING
        iv_repository_id TYPE string
        iv_algorithm     TYPE string
        it_references    TYPE zif_hithub_metadata_store=>ty_references
      RETURNING
        VALUE(rt_visible) TYPE zif_hithub_metadata_store=>ty_references.

ENDCLASS.

CLASS zcl_hithub_ref_visibility IMPLEMENTATION.

  METHOD filter.
    DATA ls_reference TYPE zif_hithub_metadata_store=>ty_reference.

    CLEAR rt_visible.
    IF iv_repository_id IS INITIAL OR iv_algorithm IS INITIAL.
      RETURN.
    ENDIF.
    LOOP AT it_references INTO ls_reference.
      IF ls_reference-repository_id <> iv_repository_id
          OR ls_reference-algorithm <> iv_algorithm.
        CONTINUE.
      ENDIF.
      IF zcl_hithub_ref_validator=>is_valid( ls_reference-name ) = abap_false
          OR zcl_hithub_oid_validator=>is_valid(
            iv_algorithm = iv_algorithm iv_oid = ls_reference-oid ) = abap_false.
        CONTINUE.
      ENDIF.
      APPEND ls_reference TO rt_visible.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
