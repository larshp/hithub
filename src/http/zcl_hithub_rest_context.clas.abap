CLASS zcl_hithub_rest_context DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_rest_context.

    CLASS-METHODS for_local
      IMPORTING
        iv_method          TYPE string
        iv_path            TYPE string
        iv_body            TYPE xstring OPTIONAL
        iv_correlation_id  TYPE string OPTIONAL
        iv_idempotency_key TYPE string OPTIONAL
        iv_if_match        TYPE string OPTIONAL
      RETURNING
        VALUE(ro_context)  TYPE REF TO zif_hithub_rest_context.

    METHODS constructor
      IMPORTING
        iv_method          TYPE string
        iv_path            TYPE string
        iv_body            TYPE xstring OPTIONAL
        iv_actor_label     TYPE string OPTIONAL
        iv_correlation_id  TYPE string OPTIONAL
        iv_idempotency_key TYPE string OPTIONAL
        iv_if_match        TYPE string OPTIONAL.

  PRIVATE SECTION.
    DATA mv_method TYPE string.
    DATA mv_path TYPE string.
    DATA mv_body TYPE xstring.
    DATA mv_actor_label TYPE string.
    DATA mv_correlation_id TYPE string.
    DATA mv_idempotency_key TYPE string.
    DATA mv_if_match TYPE string.

ENDCLASS.

CLASS zcl_hithub_rest_context IMPLEMENTATION.

  METHOD for_local.
    ro_context = NEW zcl_hithub_rest_context(
      iv_method          = iv_method
      iv_path            = iv_path
      iv_body            = iv_body
      iv_actor_label     = 'local-development'
      iv_correlation_id  = iv_correlation_id
      iv_idempotency_key = iv_idempotency_key
      iv_if_match        = iv_if_match ).
  ENDMETHOD.

  METHOD constructor.
    mv_method = iv_method.
    TRANSLATE mv_method TO UPPER CASE.
    mv_path = iv_path.
    mv_body = iv_body.
    mv_actor_label = iv_actor_label.
    mv_correlation_id = iv_correlation_id.
    mv_idempotency_key = iv_idempotency_key.
    mv_if_match = iv_if_match.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~request_method.
    rv_method = mv_method.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~path.
    rv_path = mv_path.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~body.
    rv_body = mv_body.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~actor_label.
    rv_actor = mv_actor_label.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~correlation_id.
    rv_correlation_id = mv_correlation_id.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~idempotency_key.
    rv_key = mv_idempotency_key.
  ENDMETHOD.

  METHOD zif_hithub_rest_context~if_match.
    rv_if_match = mv_if_match.
  ENDMETHOD.

ENDCLASS.
