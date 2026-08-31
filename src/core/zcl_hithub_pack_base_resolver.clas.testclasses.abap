CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS scopes_base_lookup FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD scopes_base_lookup.
    DATA(lo_store) = NEW zcl_hithub_local_object_store( ).
    DATA(lo_reader) = NEW zcl_hithub_object_reader( lo_store ).
    DATA(lo_resolver) = NEW zcl_hithub_pack_base_resolver( lo_reader ).
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA ls_key TYPE zif_hithub_object_store=>ty_object_key.
    DATA ls_read TYPE zif_hithub_object_store=>ty_object.

    ls_object-key-repository_id = 'pack-base-repository-a-00000000000'.
    ls_object-key-algorithm = 'sha1'.
    ls_object-key-oid = '1111111111111111111111111111111111111111'.
    ls_object-type = 'blob'.
    ls_object-size = 3.
    ls_object-payload = CONV xstring( '616263' ).
    lo_store->zif_hithub_object_store~write( ls_object ).

    ls_key = ls_object-key.
    ls_read = lo_resolver->read( ls_key ).
    ASSERT ls_read-key-repository_id = ls_object-key-repository_id.
    ASSERT ls_read-payload = ls_object-payload.

    ls_key-repository_id = 'pack-base-repository-b-00000000000'.
    ls_read = lo_resolver->read( ls_key ).
    ASSERT ls_read-key-repository_id IS INITIAL.
  ENDMETHOD.

ENDCLASS.
