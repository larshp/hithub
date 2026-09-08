INTERFACE zif_hithub_asset_store
  PUBLIC.

  TYPES:
    BEGIN OF ty_asset,
      name      TYPE string,
      mime_type TYPE string,
      content   TYPE xstring,
      found     TYPE abap_bool,
    END OF ty_asset.

  "! Reads one browser asset by file name, for example index.html. The SAP
  "! adapter reads the MIME repository objects that abapGit installs from
  "! package ZHITHUB_FRONTEND; the open-abap adapter serves what the local
  "! runtime registered during startup.
  METHODS read
    IMPORTING
      iv_name         TYPE string
    RETURNING
      VALUE(rs_asset) TYPE ty_asset
    RAISING
      cx_static_check.

ENDINTERFACE.
