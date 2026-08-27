REPORT zhi_ags_http_spike.

* Adapted abapGitServer discovery-flow spike.
* Run in SE38 with a 40-character HEAD OID and one advertised ref.

PARAMETERS:
  p_head TYPE string LOWER CASE OBLIGATORY,
  p_ref  TYPE string LOWER CASE OBLIGATORY.

START-OF-SELECTION.
  DATA lt_refs TYPE zcl_hi_ags_discovery_spike=>ty_refs.
  APPEND p_ref TO lt_refs.

  TRY.
      DATA(lv_body) = zcl_hi_ags_discovery_spike=>build(
        iv_service = 'git-upload-pack'
        iv_head    = p_head
        it_refs    = lt_refs ).
      WRITE: / |discovery bytes: { xstrlen( lv_body ) }|,
             / 'expected media type: application/x-git-upload-pack-advertisement',
             / 'expected cache control: no-cache'.
    CATCH zcx_abapgit_exception INTO DATA(lx_error).
      WRITE: / |discovery error: { lx_error->get_text( ) }|.
  ENDTRY.
