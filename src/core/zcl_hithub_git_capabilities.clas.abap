CLASS zcl_hithub_git_capabilities DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_capabilities TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLASS-METHODS advertised
      IMPORTING
        iv_head_ref TYPE string DEFAULT 'refs/heads/main'
      RETURNING
        VALUE(rt_capabilities) TYPE ty_capabilities.

    CLASS-METHODS render
      IMPORTING
        it_capabilities TYPE ty_capabilities
      RETURNING
        VALUE(rv_text) TYPE string.

ENDCLASS.

CLASS zcl_hithub_git_capabilities IMPLEMENTATION.

  METHOD advertised.
    CLEAR rt_capabilities.
    APPEND 'no-thin' TO rt_capabilities.
    APPEND 'no-progress' TO rt_capabilities.
    IF iv_head_ref IS NOT INITIAL.
      APPEND |symref=HEAD:{ iv_head_ref }| TO rt_capabilities.
    ENDIF.
    APPEND 'agent=hithub' TO rt_capabilities.
  ENDMETHOD.

  METHOD render.
    CLEAR rv_text.
    CONCATENATE LINES OF it_capabilities INTO rv_text SEPARATED BY space.
  ENDMETHOD.

ENDCLASS.
