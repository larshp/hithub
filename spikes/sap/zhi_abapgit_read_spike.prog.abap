*&---------------------------------------------------------------------*
*& Report ZHI_ABAPGIT_READ_SPIKE
*&---------------------------------------------------------------------*
*& SAP-only compatibility spike for the pinned abapGit v1.134.0 API.
*& The report calls zcl_abapgit_git_commit=>get_by_commit to retrieve and
*& parse one commit object from a Git Smart HTTP repository.
*&---------------------------------------------------------------------*
REPORT zhi_abapgit_read_spike.

PARAMETERS:
  p_url    TYPE string LOWER CASE DEFAULT 'https://github.com/abapGit/abapGit.git',
  p_sha1   TYPE zif_abapgit_git_definitions=>ty_sha1
           DEFAULT 'b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f',
  p_deepen TYPE i DEFAULT 0.

START-OF-SELECTION.
  DATA lt_commits TYPE zif_abapgit_git_definitions=>ty_commit_tt.
  DATA ls_commit LIKE LINE OF lt_commits.

  IF p_deepen < 0.
    MESSAGE 'Deepen level must not be negative' TYPE 'E'.
  ENDIF.

  TRY.
      lt_commits = zcl_abapgit_git_commit=>get_by_commit(
        iv_commit_hash  = p_sha1
        iv_repo_url     = p_url
        iv_deepen_level = p_deepen ).
    CATCH zcx_abapgit_exception INTO DATA(lo_error).
      MESSAGE lo_error->get_text( ) TYPE 'E'.
  ENDTRY.

  READ TABLE lt_commits WITH KEY sha1 = p_sha1 INTO ls_commit.
  IF sy-subrc <> 0.
    MESSAGE 'abapGit did not return the requested commit object' TYPE 'E'.
  ENDIF.

  WRITE: / 'abapGit SAP read-object spike: PASS',
         / |repository: { p_url }|,
         / |requested object: { p_sha1 }|,
         / |returned object: { ls_commit-sha1 }|,
         / |author: { ls_commit-author } <{ ls_commit-email }>|,
         / |time: { ls_commit-time }|,
         / |message: { ls_commit-message }|.
