INTERFACE zif_hithub_rest_context
  PUBLIC.

  METHODS request_method
    RETURNING
      VALUE(rv_method) TYPE string.
  METHODS path
    RETURNING
      VALUE(rv_path) TYPE string.
  METHODS body
    RETURNING
      VALUE(rv_body) TYPE xstring.
  METHODS actor_label
    RETURNING
      VALUE(rv_actor) TYPE string.
  METHODS correlation_id
    RETURNING
      VALUE(rv_correlation_id) TYPE string.
  METHODS idempotency_key
    RETURNING
      VALUE(rv_key) TYPE string.
  METHODS if_match
    RETURNING
      VALUE(rv_if_match) TYPE string.

ENDINTERFACE.
