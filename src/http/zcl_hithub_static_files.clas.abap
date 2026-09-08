CLASS zcl_hithub_static_files DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES BEGIN OF ty_response.
    TYPES   status        TYPE i.
    TYPES   reason        TYPE string.
    TYPES   content_type  TYPE string.
    TYPES   cache_control TYPE string.
    TYPES   etag          TYPE string.
    TYPES   body          TYPE xstring.
    TYPES END OF ty_response.

    METHODS constructor
      IMPORTING
        io_store TYPE REF TO zif_hithub_asset_store.

    "! Serves the browser assets from the asset store. The path is the ICF
    "! path info, so the service node prefix is already removed and the same
    "! paths resolve on an installed service and in the local runtime. The ICF
    "! handler cannot propagate an exception, so a failed read is a response.
    METHODS serve
      IMPORTING
        iv_path            TYPE string
        iv_if_none_match   TYPE string OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE ty_response.

    "! index.html answers the single page application routes, so /ui paths
    "! resolve to the application shell instead of a file. Everything that is
    "! neither the shell nor a top level file name stays unresolved, which
    "! keeps the handler's 404 for unknown paths.
    CLASS-METHODS resolve_name
      IMPORTING
        iv_path        TYPE string
      RETURNING
        VALUE(rv_name) TYPE string.

  PRIVATE SECTION.
    CONSTANTS c_shell TYPE string VALUE 'index.html'.

    DATA mo_store TYPE REF TO zif_hithub_asset_store.

    "! The extension decides the response type, so both runtimes answer with
    "! the same header no matter which mime type the MIME repository derived
    "! on import. The stored type only covers assets added later.
    CLASS-METHODS content_type_for
      IMPORTING
        iv_name                TYPE string
        iv_mime_type           TYPE string
      RETURNING
        VALUE(rv_content_type) TYPE string.

    CLASS-METHODS etag_for
      IMPORTING
        iv_content     TYPE xstring
      RETURNING
        VALUE(rv_etag) TYPE string
      RAISING
        cx_static_check.

ENDCLASS.

CLASS zcl_hithub_static_files IMPLEMENTATION.

  METHOD constructor.
    mo_store = io_store.
  ENDMETHOD.

  METHOD resolve_name.
    DATA lv_path  TYPE string.
    DATA lv_query TYPE string.

    CLEAR rv_name.
    lv_path = iv_path.
    IF lv_path CS '?'.
      SPLIT lv_path AT '?' INTO lv_path lv_query.
    ENDIF.
    IF lv_path IS INITIAL OR lv_path = '/'.
      rv_name = c_shell.
      RETURN.
    ENDIF.
    IF lv_path = '/ui' OR lv_path CP '/ui/*'.
      rv_name = c_shell.
      RETURN.
    ENDIF.
    " A top level file name is the only asset shape the frontend requests,
    " because index.html links /app.js and /styles.css from the root.
    FIND REGEX '^/([A-Za-z0-9._-]+\.[A-Za-z0-9]+)$' IN lv_path
      SUBMATCHES rv_name.
    IF sy-subrc <> 0.
      CLEAR rv_name.
    ENDIF.
  ENDMETHOD.

  METHOD serve.
    DATA ls_asset TYPE zif_hithub_asset_store=>ty_asset.
    DATA lv_name  TYPE string.

    CLEAR rs_response.
    lv_name = resolve_name( iv_path ).
    IF lv_name IS INITIAL OR mo_store IS NOT BOUND.
      rs_response-status = 404.
      rs_response-reason = 'Not Found'.
      RETURN.
    ENDIF.
    TRY.
        ls_asset = mo_store->read( lv_name ).
        IF ls_asset-found = abap_true.
          " The assets are not fingerprinted, so the browser has to
          " revalidate and the entity tag is what keeps that cheap.
          rs_response-etag = etag_for( ls_asset-content ).
        ENDIF.
      CATCH cx_static_check.
        CLEAR rs_response.
        rs_response-status = 500.
        rs_response-reason = 'Internal Server Error'.
        RETURN.
    ENDTRY.
    IF ls_asset-found <> abap_true.
      CLEAR rs_response.
      rs_response-status = 404.
      rs_response-reason = 'Not Found'.
      RETURN.
    ENDIF.
    rs_response-cache_control = 'no-cache'.
    IF iv_if_none_match IS NOT INITIAL
        AND iv_if_none_match = rs_response-etag.
      rs_response-status = 304.
      rs_response-reason = 'Not Modified'.
      RETURN.
    ENDIF.
    rs_response-status = 200.
    rs_response-reason = 'OK'.
    rs_response-content_type = content_type_for(
      iv_name      = lv_name
      iv_mime_type = ls_asset-mime_type ).
    rs_response-body = ls_asset-content.
  ENDMETHOD.

  METHOD content_type_for.
    IF iv_name CP '*.html'.
      rv_content_type = 'text/html; charset=utf-8'.
    ELSEIF iv_name CP '*.js'.
      rv_content_type = 'text/javascript; charset=utf-8'.
    ELSEIF iv_name CP '*.css'.
      rv_content_type = 'text/css; charset=utf-8'.
    ELSEIF iv_name CP '*.svg'.
      rv_content_type = 'image/svg+xml'.
    ELSEIF iv_name CP '*.json'.
      rv_content_type = 'application/json'.
    ELSEIF iv_mime_type IS NOT INITIAL.
      rv_content_type = iv_mime_type.
    ELSE.
      rv_content_type = 'application/octet-stream'.
    ENDIF.
  ENDMETHOD.

  METHOD etag_for.
    DATA lv_hash TYPE xstring.
    DATA lv_hex  TYPE string.

    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING
        if_algorithm   = 'sha1'
        if_data        = iv_content
      IMPORTING
        ef_hashxstring = lv_hash ).
    lv_hex = lv_hash.
    TRANSLATE lv_hex TO LOWER CASE.
    rv_etag = |"{ lv_hex }"|.
  ENDMETHOD.

ENDCLASS.
