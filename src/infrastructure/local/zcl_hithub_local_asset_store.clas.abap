CLASS zcl_hithub_local_asset_store DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_asset_store.

    "! Registers one browser asset for the local runtime. The open-abap
    "! process has no MIME repository, so server/index.mjs reads the
    "! serialized SMIM data files from src/frontend and registers them here
    "! during startup. That keeps src/frontend the single asset source for
    "! both runtimes: SAP reads the same bytes back out of the MIME
    "! repository after abapGit installed them. The content is base64 because
    "! a byte string does not cross the transpiler boundary.
    CLASS-METHODS register
      IMPORTING
        iv_name      TYPE string
        iv_mime_type TYPE string
        iv_content   TYPE string.

    CLASS-METHODS reset.

  PRIVATE SECTION.
    TYPES ty_assets TYPE STANDARD TABLE OF zif_hithub_asset_store=>ty_asset
      WITH EMPTY KEY.

    CLASS-DATA gt_assets TYPE ty_assets.

ENDCLASS.

CLASS zcl_hithub_local_asset_store IMPLEMENTATION.

  METHOD register.
    DATA ls_asset TYPE zif_hithub_asset_store=>ty_asset.

    IF iv_name IS INITIAL.
      RETURN.
    ENDIF.
    DELETE gt_assets WHERE name = iv_name.
    ls_asset-name = iv_name.
    ls_asset-mime_type = iv_mime_type.
    ls_asset-content = cl_http_utility=>decode_x_base64( iv_content ).
    ls_asset-found = abap_true.
    APPEND ls_asset TO gt_assets.
  ENDMETHOD.

  METHOD reset.
    CLEAR gt_assets.
  ENDMETHOD.

  METHOD zif_hithub_asset_store~read.
    CLEAR rs_asset.
    IF iv_name IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE gt_assets INTO rs_asset WITH KEY name = iv_name.
    IF sy-subrc <> 0.
      CLEAR rs_asset.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
