CLASS zcl_hithub_work_number DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_max_digits TYPE i VALUE 9.

    "! Issues and pull requests draw from one sequence per repository, so a
    "! repository never has both an issue #5 and a pull request #5.
    CLASS-METHODS next
      IMPORTING
        iv_repository_id TYPE string
      RETURNING
        VALUE(rv_number) TYPE i.

    CLASS-METHODS parse
      IMPORTING
        iv_id            TYPE string
      RETURNING
        VALUE(rv_number) TYPE i.

  PRIVATE SECTION.
    CLASS-METHODS highest_issue
      IMPORTING
        iv_repository_id  TYPE string
      RETURNING
        VALUE(rv_highest) TYPE i.

    CLASS-METHODS highest_pull_request
      IMPORTING
        iv_repository_id  TYPE string
      RETURNING
        VALUE(rv_highest) TYPE i.
ENDCLASS.

CLASS zcl_hithub_work_number IMPLEMENTATION.

  METHOD parse.
    CLEAR rv_number.
    IF iv_id IS INITIAL OR strlen( iv_id ) > c_max_digits
        OR iv_id CN '0123456789'.
      RETURN.
    ENDIF.
    rv_number = iv_id.
  ENDMETHOD.

  METHOD next.
    DATA lv_highest TYPE i.
    DATA lv_pulls TYPE i.

    rv_number = 0.
    IF iv_repository_id IS INITIAL.
      RETURN.
    ENDIF.
    lv_highest = highest_issue( iv_repository_id ).
    lv_pulls = highest_pull_request( iv_repository_id ).
    IF lv_pulls > lv_highest.
      lv_highest = lv_pulls.
    ENDIF.
    rv_number = lv_highest + 1.
  ENDMETHOD.

  METHOD highest_issue.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_issue.
    DATA ls_row TYPE zhi_issue.
    DATA lv_number TYPE i.

    CLEAR rv_highest.
    SELECT id FROM zhi_issue INTO CORRESPONDING FIELDS OF TABLE @lt_rows
      WHERE repository_id = @iv_repository_id.
    LOOP AT lt_rows INTO ls_row.
      lv_number = parse( |{ ls_row-id }| ).
      IF lv_number > rv_highest.
        rv_highest = lv_number.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD highest_pull_request.
    DATA lt_rows TYPE STANDARD TABLE OF zhi_pull_request.
    DATA ls_row TYPE zhi_pull_request.
    DATA lv_number TYPE i.

    CLEAR rv_highest.
    SELECT id FROM zhi_pull_request INTO CORRESPONDING FIELDS OF TABLE @lt_rows
      WHERE repository_id = @iv_repository_id.
    LOOP AT lt_rows INTO ls_row.
      lv_number = parse( |{ ls_row-id }| ).
      IF lv_number > rv_highest.
        rv_highest = lv_number.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
