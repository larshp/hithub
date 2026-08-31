INTERFACE zif_hithub_request_context
  PUBLIC.

  METHODS actor_label
    RETURNING
      VALUE(rv_actor) TYPE string.

  METHODS correlation_id
    RETURNING
      VALUE(rv_correlation_id) TYPE string.

ENDINTERFACE.
