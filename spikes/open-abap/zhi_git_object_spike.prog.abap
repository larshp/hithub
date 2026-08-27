REPORT zhi_git_object_spike.

* open-abap counterpart of the SAP spike. It intentionally calls the same
* abapGit public API so the result can be compared across runtimes.

PARAMETERS:
  p_url TYPE string LOWER CASE OBLIGATORY,
  p_oid TYPE zif_abapgit_git_definitions=>ty_sha1 LOWER CASE OBLIGATORY.

START-OF-SELECTION.
  PERFORM read_object.

FORM read_object.
  DATA:
    lt_objects TYPE zif_abapgit_definitions=>ty_objects_tt,
    lv_commit  TYPE zif_abapgit_git_definitions=>ty_sha1.
  FIELD-SYMBOLS:
    <ls_object> LIKE LINE OF lt_objects.

  TRY.
      zcl_abapgit_git_transport=>upload_pack_by_commit(
        EXPORTING
          iv_url     = p_url
          iv_hash    = p_oid
        IMPORTING
          et_objects = lt_objects
          ev_commit  = lv_commit ).

      READ TABLE lt_objects ASSIGNING <ls_object>
        WITH KEY sha1 = p_oid.
      IF sy-subrc <> 0.
        WRITE: / |Object { p_oid } was not returned by abapGit|.
        RETURN.
      ENDIF.

      WRITE: / |commit: { lv_commit }|,
             / |object: { <ls_object>-sha1 }|,
             / |type: { <ls_object>-type }|,
             / |payload bytes: { xstrlen( <ls_object>-data ) }|.
    CATCH zcx_abapgit_exception INTO DATA(lx_error).
      WRITE: / |abapGit error: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.
