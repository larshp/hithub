*&---------------------------------------------------------------------*
*& Report ZHI_ABAPGIT_OPEN_READ_SPIKE
*&---------------------------------------------------------------------*
*& Non-interactive open-abap compatibility probe for the pinned abapGit
*& v1.134.0 API. It intentionally makes the same get_by_commit call as
*& the SAP report, using constants because open-abap does not transpile
*& interactive selection-screen parameters.
*&---------------------------------------------------------------------*
REPORT zhi_abapgit_open_read_spike.

CONSTANTS:
  lc_url  TYPE string VALUE 'https://github.com/abapGit/abapGit.git',
  lc_sha1 TYPE zif_abapgit_git_definitions=>ty_sha1
           VALUE 'b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f'.

CLASS lcl_progress DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_abapgit_progress.
ENDCLASS.

CLASS lcl_progress IMPLEMENTATION.
  METHOD zif_abapgit_progress~show.
  ENDMETHOD.

  METHOD zif_abapgit_progress~set_total.
  ENDMETHOD.

  METHOD zif_abapgit_progress~off.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA lo_progress TYPE REF TO zif_abapgit_progress.
  DATA lt_commits TYPE zif_abapgit_git_definitions=>ty_commit_tt.
  DATA ls_commit LIKE LINE OF lt_commits.

  CREATE OBJECT lo_progress TYPE lcl_progress.
  zcl_abapgit_progress=>set_instance( lo_progress ).

  TRY.
      lt_commits = zcl_abapgit_git_commit=>get_by_commit(
        iv_commit_hash  = lc_sha1
        iv_repo_url     = lc_url
        iv_deepen_level = 0 ).
    CATCH zcx_abapgit_exception INTO DATA(lo_error).
      WRITE: / 'abapGit open-abap read-object spike: FAIL',
             / lo_error->get_text( ).
  ENDTRY.

  IF lt_commits IS INITIAL.
    WRITE: / 'abapGit open-abap read-object spike: FAIL',
           / 'abapGit did not return the requested commit object'.
  ELSE.
    READ TABLE lt_commits WITH KEY sha1 = lc_sha1 INTO ls_commit.
    IF sy-subrc <> 0.
      WRITE: / 'abapGit open-abap read-object spike: FAIL',
             / 'abapGit did not return the requested commit object'.
    ELSE.
      WRITE: / 'abapGit open-abap read-object spike: PASS',
             / |repository: { lc_url }|,
             / |requested object: { lc_sha1 }|,
             / |returned object: { ls_commit-sha1 }|,
             / |author: { ls_commit-author } <{ ls_commit-email }>|,
             / |time: { ls_commit-time }|,
             / |message: { ls_commit-message }|.
    ENDIF.
  ENDIF.
