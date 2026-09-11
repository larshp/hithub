CLASS zcl_hithub_system_identity DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hithub_identity.

ENDCLASS.

CLASS zcl_hithub_system_identity IMPLEMENTATION.

  METHOD zif_hithub_identity~uuid.
    rv_uuid = cl_system_uuid=>if_system_uuid_static~create_uuid_c36( ).
  ENDMETHOD.

  METHOD zif_hithub_identity~random_bytes.
    rv_bytes = cl_system_uuid=>if_system_uuid_static~create_uuid_x16( ).
  ENDMETHOD.

ENDCLASS.
