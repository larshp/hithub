CLASS zcl_hi_ags_discovery_spike DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_refs TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLASS-METHODS build
      IMPORTING
        iv_service TYPE string
        iv_head    TYPE string
        it_refs    TYPE ty_refs
      RETURNING
        VALUE(rv_body) TYPE xstring
      RAISING
        zcx_abapgit_exception.
ENDCLASS.

CLASS zcl_hi_ags_discovery_spike IMPLEMENTATION.

  METHOD build.
    DATA:
      lv_body        TYPE string,
      lv_capabilities TYPE string,
      lv_line        TYPE string,
      lv_refs        TYPE string.
    FIELD-SYMBOLS <lv_ref> LIKE LINE OF it_refs.

    IF iv_service IS INITIAL OR iv_head IS INITIAL.
      zcx_abapgit_exception=>raise( 'Discovery requires service and HEAD' ).
    ENDIF.

    " Adapted from abapGitServer ZCL_AGS_SERVICE_GIT->BRANCH_LIST at
    " 3808345145b4d0fa78c74cbabf4964383c1aa1ad. The MIT attribution is kept
    " in docs/attributions.md; HitHub-specific response policy is added here.
    lv_capabilities = 'multi_ack no-thin side-band-64k shallow no-progress'
      && ' include-tag report-status multi_ack_detailed no-done'
      && ' symref=HEAD:refs/heads/main agent=hithub'.

    lv_body = zcl_abapgit_git_utils=>pkt_string(
      |# service={ iv_service }| && cl_abap_char_utilities=>newline ).
    lv_line = iv_head && | HEAD| && zcl_abapgit_git_utils=>get_null( )
      && lv_capabilities && cl_abap_char_utilities=>newline.
    lv_body = lv_body && zcl_abapgit_git_utils=>pkt_string( lv_line ).

    LOOP AT it_refs ASSIGNING <lv_ref>.
      lv_line = <lv_ref> && cl_abap_char_utilities=>newline.
      lv_refs = lv_refs && zcl_abapgit_git_utils=>pkt_string( lv_line ).
    ENDLOOP.

    lv_body = lv_body && lv_refs && '0000'.
    rv_body = cl_abap_codepage=>convert_to( source = lv_body ).
  ENDMETHOD.

ENDCLASS.
