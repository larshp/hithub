CLASS zcl_hithub_sap_asset_store DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_asset_store.

    "! MIME repository folder the SMIM objects in package ZHITHUB_FRONTEND
    "! deserialize into. Keep it aligned with the URL in the .smim.xml files,
    "! because abapGit installs the assets under exactly that path.
    CONSTANTS c_folder TYPE string VALUE '/SAP/PUBLIC/zhithub'.

ENDCLASS.

CLASS zcl_hithub_sap_asset_store IMPLEMENTATION.

  METHOD zif_hithub_asset_store~read.
    DATA li_api     TYPE REF TO if_mr_api.
    DATA lv_content TYPE xstring.
    DATA lv_mime    TYPE string.

    CLEAR rs_asset.
    IF iv_name IS INITIAL.
      RETURN.
    ENDIF.
    li_api = cl_mime_repository_api=>if_mr_api~get_api( ).
    li_api->get(
      EXPORTING
        i_url              = |{ c_folder }/{ iv_name }|
      IMPORTING
        e_content          = lv_content
        e_mime_type        = lv_mime
      EXCEPTIONS
        parameter_missing  = 1
        error_occured      = 2
        not_found          = 3
        permission_failure = 4
        OTHERS             = 5 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    rs_asset-name = iv_name.
    rs_asset-mime_type = lv_mime.
    rs_asset-content = lv_content.
    rs_asset-found = abap_true.
  ENDMETHOD.

ENDCLASS.
