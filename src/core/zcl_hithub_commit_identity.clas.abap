CLASS zcl_hithub_commit_identity DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_identity,
        name         TYPE string,
        email        TYPE string,
        unix_seconds TYPE int8,
        timezone     TYPE string,
      END OF ty_identity.

    CLASS-METHODS parse
      IMPORTING
        iv_identity        TYPE string
      RETURNING
        VALUE(rs_identity) TYPE ty_identity.

ENDCLASS.

CLASS zcl_hithub_commit_identity IMPLEMENTATION.

  METHOD parse.
    DATA lv_name TYPE string.
    DATA lv_rest TYPE string.
    DATA lv_email TYPE string.
    DATA lv_suffix TYPE string.
    DATA lv_timestamp TYPE string.

    CLEAR rs_identity.
    SPLIT iv_identity AT '<' INTO lv_name lv_rest.
    SPLIT lv_rest AT '>' INTO lv_email lv_suffix.
    CONDENSE lv_name.
    CONDENSE lv_email.
    CONDENSE lv_suffix.
    SPLIT lv_suffix AT space INTO lv_timestamp rs_identity-timezone.
    rs_identity-name = lv_name.
    rs_identity-email = lv_email.
    IF lv_timestamp IS NOT INITIAL.
      rs_identity-unix_seconds = CONV int8( lv_timestamp ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
