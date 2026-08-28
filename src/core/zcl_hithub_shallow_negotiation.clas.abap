CLASS zcl_hithub_shallow_negotiation DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_commit,
        oid     TYPE string,
        parents TYPE zcl_hithub_commit_codec=>ty_parents,
      END OF ty_commit,
      ty_commits TYPE STANDARD TABLE OF ty_commit WITH DEFAULT KEY.

    CLASS-METHODS build
      IMPORTING
        it_start_oids TYPE zcl_hithub_upload_request=>ty_lines
        it_commits    TYPE ty_commits
        iv_depth      TYPE i
      RETURNING
        VALUE(rv_response) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_shallow_negotiation IMPLEMENTATION.

  METHOD build.
    TYPES:
      BEGIN OF ty_visit,
        oid   TYPE string,
        depth TYPE i,
      END OF ty_visit,
      ty_visits TYPE STANDARD TABLE OF ty_visit WITH DEFAULT KEY.
    DATA lt_queue TYPE ty_visits.
    DATA lt_seen TYPE zcl_hithub_upload_request=>ty_lines.
    DATA lt_boundaries TYPE zcl_hithub_upload_request=>ty_lines.
    DATA ls_visit TYPE ty_visit.
    DATA ls_commit TYPE ty_commit.
    DATA lv_start_oid TYPE string.
    DATA lv_parent_oid TYPE string.
    DATA lv_next_depth TYPE i.
    DATA lv_line TYPE string.
    DATA lv_text TYPE xstring.
    DATA lv_packet TYPE xstring.

    CLEAR rv_response.
    IF iv_depth <= 0.
      RETURN.
    ENDIF.
    LOOP AT it_start_oids INTO lv_start_oid.
      IF zcl_hithub_oid_validator=>is_valid(
          iv_algorithm = 'sha1' iv_oid = lv_start_oid ) = abap_true.
        CLEAR ls_visit.
        ls_visit-oid = lv_start_oid.
        APPEND ls_visit TO lt_queue.
      ENDIF.
    ENDLOOP.

    DATA lv_index TYPE i.
    lv_index = 1.
    WHILE lv_index <= lines( lt_queue ).
      READ TABLE lt_queue INTO ls_visit INDEX lv_index.
      lv_index = lv_index + 1.
      READ TABLE lt_seen WITH KEY table_line = ls_visit-oid
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      APPEND ls_visit-oid TO lt_seen.
      IF ls_visit-depth + 1 >= iv_depth.
        APPEND ls_visit-oid TO lt_boundaries.
        CONTINUE.
      ENDIF.
      READ TABLE it_commits INTO ls_commit WITH KEY oid = ls_visit-oid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      LOOP AT ls_commit-parents INTO lv_parent_oid.
        lv_next_depth = ls_visit-depth + 1.
        CLEAR ls_visit.
        ls_visit-oid = lv_parent_oid.
        ls_visit-depth = lv_next_depth.
        APPEND ls_visit TO lt_queue.
      ENDLOOP.
    ENDWHILE.

    LOOP AT lt_boundaries INTO lv_start_oid.
      lv_line = |shallow { lv_start_oid }| && cl_abap_char_utilities=>newline.
      lv_text = cl_abap_codepage=>convert_to( source = lv_line ).
      lv_packet = zcl_hithub_pkt_line_codec=>encode( lv_text ).
      CONCATENATE rv_response lv_packet INTO rv_response IN BYTE MODE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
