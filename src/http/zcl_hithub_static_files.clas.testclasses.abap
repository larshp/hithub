CLASS lcl_asset_store DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_asset_store.

    METHODS constructor
      IMPORTING
        iv_mime_type TYPE string DEFAULT 'text/html'.

    DATA mv_last_name TYPE string READ-ONLY.

  PRIVATE SECTION.
    DATA mv_mime_type TYPE string.

ENDCLASS.

CLASS lcl_asset_store IMPLEMENTATION.

  METHOD constructor.
    mv_mime_type = iv_mime_type.
  ENDMETHOD.

  METHOD zif_hithub_asset_store~read.
    CLEAR rs_asset.
    mv_last_name = iv_name.
    IF iv_name <> 'index.html' AND iv_name <> 'app.js'.
      RETURN.
    ENDIF.
    rs_asset-name = iv_name.
    rs_asset-mime_type = mv_mime_type.
    rs_asset-content = CONV xstring( '48690A' ).
    rs_asset-found = abap_true.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_failing_store DEFINITION.

  PUBLIC SECTION.
    INTERFACES zif_hithub_asset_store.

ENDCLASS.

CLASS lcl_failing_store IMPLEMENTATION.

  METHOD zif_hithub_asset_store~read.
    RAISE EXCEPTION TYPE cx_abap_message_digest.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_static_files DEFINITION
  FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resolves_the_shell FOR TESTING RAISING cx_static_check.
    METHODS resolves_asset_names FOR TESTING RAISING cx_static_check.
    METHODS leaves_other_paths_unresolved FOR TESTING RAISING cx_static_check.
    METHODS serves_the_shell FOR TESTING RAISING cx_static_check.
    METHODS types_the_asset FOR TESTING RAISING cx_static_check.
    METHODS revalidates_with_the_etag FOR TESTING RAISING cx_static_check.
    METHODS reports_missing_assets FOR TESTING RAISING cx_static_check.
    METHODS reports_a_failing_store FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_static_files IMPLEMENTATION.

  METHOD resolves_the_shell.
    " The frontend routes live below /ui and are rendered by index.html, so
    " they cannot 404 on a deep link the way a missing file does.
    ASSERT zcl_hithub_static_files=>resolve_name( '/' ) = 'index.html'.
    ASSERT zcl_hithub_static_files=>resolve_name( '' ) = 'index.html'.
    ASSERT zcl_hithub_static_files=>resolve_name( '/ui' ) = 'index.html'.
    ASSERT zcl_hithub_static_files=>resolve_name( '/ui/create' ) = 'index.html'.
    ASSERT zcl_hithub_static_files=>resolve_name(
      '/ui/repos/demo/blob/main/README.md' ) = 'index.html'.
    ASSERT zcl_hithub_static_files=>resolve_name( '/?q=alpha' ) = 'index.html'.
  ENDMETHOD.

  METHOD resolves_asset_names.
    ASSERT zcl_hithub_static_files=>resolve_name( '/app.js' ) = 'app.js'.
    ASSERT zcl_hithub_static_files=>resolve_name(
      '/styles.css' ) = 'styles.css'.
    ASSERT zcl_hithub_static_files=>resolve_name(
      '/index.html' ) = 'index.html'.
  ENDMETHOD.

  METHOD leaves_other_paths_unresolved.
    " Only the shell and root level file names are the frontend's, so an
    " unknown path still gets the handler's 404 instead of the shell.
    ASSERT zcl_hithub_static_files=>resolve_name( '/unknown' ) IS INITIAL.
    ASSERT zcl_hithub_static_files=>resolve_name(
      '/assets/app.js' ) IS INITIAL.
    ASSERT zcl_hithub_static_files=>resolve_name(
      '/../secret.txt' ) IS INITIAL.
  ENDMETHOD.

  METHOD serves_the_shell.
    DATA(lo_store) = NEW lcl_asset_store( ).
    DATA(lo_service) = NEW zcl_hithub_static_files( lo_store ).

    DATA(ls_response) = lo_service->serve( '/ui/repos/demo' ).
    ASSERT lo_store->mv_last_name = 'index.html'.
    ASSERT ls_response-status = 200.
    ASSERT ls_response-content_type = 'text/html; charset=utf-8'.
    ASSERT ls_response-cache_control = 'no-cache'.
    ASSERT ls_response-body = CONV xstring( '48690A' ).
    ASSERT ls_response-etag IS NOT INITIAL.
  ENDMETHOD.

  METHOD types_the_asset.
    " The MIME repository derives its own type on import, so the extension
    " decides and both runtimes answer with the same header.
    DATA(lo_service) = NEW zcl_hithub_static_files(
      NEW lcl_asset_store( 'application/octet-stream' ) ).

    DATA(ls_response) = lo_service->serve( '/app.js' ).
    ASSERT ls_response-status = 200.
    ASSERT ls_response-content_type = 'text/javascript; charset=utf-8'.
  ENDMETHOD.

  METHOD revalidates_with_the_etag.
    DATA(lo_service) = NEW zcl_hithub_static_files(
      NEW lcl_asset_store( ) ).

    DATA(ls_first) = lo_service->serve( '/index.html' ).
    DATA(ls_second) = lo_service->serve(
      iv_path          = '/index.html'
      iv_if_none_match = ls_first-etag ).
    ASSERT ls_second-status = 304.
    ASSERT ls_second-body IS INITIAL.
    ASSERT ls_second-etag = ls_first-etag.
    DATA(ls_stale) = lo_service->serve(
      iv_path          = '/index.html'
      iv_if_none_match = '"0000000000000000000000000000000000000000"' ).
    ASSERT ls_stale-status = 200.
  ENDMETHOD.

  METHOD reports_missing_assets.
    DATA(lo_service) = NEW zcl_hithub_static_files(
      NEW lcl_asset_store( ) ).

    ASSERT lo_service->serve( '/styles.css' )-status = 404.
    ASSERT lo_service->serve( '/unknown' )-status = 404.
  ENDMETHOD.

  METHOD reports_a_failing_store.
    " The ICF handler has no way to propagate an exception, so a broken MIME
    " repository read has to become a response.
    DATA(lo_service) = NEW zcl_hithub_static_files(
      NEW lcl_failing_store( ) ).

    ASSERT lo_service->serve( '/index.html' )-status = 500.
  ENDMETHOD.

ENDCLASS.
