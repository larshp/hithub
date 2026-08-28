CLASS zcl_hithub_pack_codec DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_objects TYPE STANDARD TABLE OF zif_hithub_object_store=>ty_object
      WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        io_compression  TYPE REF TO zif_hithub_compression
        io_base_resolver TYPE REF TO zcl_hithub_pack_base_resolver OPTIONAL.

    METHODS unpack
      IMPORTING
        iv_pack          TYPE xstring
        iv_repository_id TYPE string
        iv_algorithm     TYPE string DEFAULT 'sha1'
        iv_max_delta_depth TYPE i DEFAULT 50
      RETURNING
        VALUE(rt_objects) TYPE ty_objects.

    METHODS repack
      IMPORTING
        it_objects TYPE ty_objects
      RETURNING
        VALUE(rv_pack) TYPE xstring
      RAISING
        cx_static_check.

  PRIVATE SECTION.
    DATA mo_compression TYPE REF TO zif_hithub_compression.
    DATA mo_base_resolver TYPE REF TO zcl_hithub_pack_base_resolver.

    TYPES:
      BEGIN OF ty_decoded,
        object       TYPE zif_hithub_object_store=>ty_object,
        pack_offset  TYPE i,
        delta_depth  TYPE i,
      END OF ty_decoded,
      ty_decoded_objects TYPE STANDARD TABLE OF ty_decoded WITH DEFAULT KEY.

ENDCLASS.

CLASS zcl_hithub_pack_codec IMPLEMENTATION.

  METHOD constructor.
    mo_compression = io_compression.
    mo_base_resolver = io_base_resolver.
  ENDMETHOD.

  METHOD unpack.
    DATA ls_header TYPE zcl_hithub_pack_header=>ty_header.
    DATA ls_entry TYPE zcl_hithub_pack_entry=>ty_entry.
    DATA ls_stream TYPE zif_hithub_compression=>ty_stream_result.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_body_length TYPE i.
    DATA lv_position TYPE i.
    DATA lv_entry_data TYPE xstring.
    DATA lv_stream_data TYPE xstring.
    DATA lv_compressed_offset TYPE i.
    DATA lv_base_offset TYPE i.
    DATA lv_stream_length TYPE i.
    DATA lv_remaining TYPE i.
    DATA lv_oid TYPE string.
    DATA lv_delta_depth TYPE i.
    DATA lv_base_found TYPE abap_bool.
    DATA ls_base TYPE zif_hithub_object_store=>ty_object.
    DATA ls_base_decoded TYPE ty_decoded.
    DATA ls_decoded TYPE ty_decoded.
    DATA lt_decoded TYPE ty_decoded_objects.
    DATA ls_base_key TYPE zif_hithub_object_store=>ty_object_key.

    CLEAR rt_objects.
    IF mo_compression IS INITIAL
        OR zcl_hithub_pack_trailer=>is_valid( iv_pack ) = abap_false.
      RETURN.
    ENDIF.
    ls_header = zcl_hithub_pack_header=>parse( iv_pack ).
    IF ls_header-signature IS INITIAL OR xstrlen( iv_pack ) <= 20.
      RETURN.
    ENDIF.
    lv_body_length = xstrlen( iv_pack ) - 20.
    lv_position = 12.
    DO ls_header-object_count TIMES.
      IF lv_position >= lv_body_length.
        CLEAR rt_objects.
        RETURN.
      ENDIF.
      lv_remaining = lv_body_length - lv_position.
      lv_entry_data = iv_pack+lv_position(lv_remaining).
      ls_entry = zcl_hithub_pack_entry=>parse( lv_entry_data ).
      IF ls_entry-type IS INITIAL.
        CLEAR rt_objects.
        RETURN.
      ENDIF.
      lv_compressed_offset = lv_position + ls_entry-data_offset.
      IF lv_compressed_offset >= lv_body_length.
        CLEAR rt_objects.
        RETURN.
      ENDIF.
      lv_stream_length = lv_body_length - lv_compressed_offset.
      lv_stream_data = iv_pack+lv_compressed_offset(lv_stream_length).
      ls_stream = mo_compression->decompress_stream( lv_stream_data ).
      IF ls_stream-consumed_bytes <= 0
          OR ls_stream-consumed_bytes > xstrlen( lv_stream_data )
          OR xstrlen( ls_stream-raw_data ) <> ls_entry-size.
        CLEAR rt_objects.
        RETURN.
      ENDIF.
      CLEAR ls_object.
      ls_object-key-repository_id = iv_repository_id.
      ls_object-key-algorithm = iv_algorithm.
      IF ls_entry-is_delta = abap_false.
        ls_object-type = ls_entry-type.
        ls_object-size = xstrlen( ls_stream-raw_data ).
        ls_object-payload = ls_stream-raw_data.
      ELSE.
        CLEAR: ls_base, lv_base_found.
        IF ls_entry-type = 'ofs-delta'.
          IF lv_position <= ls_entry-base_distance.
            CLEAR rt_objects.
            RETURN.
          ENDIF.
          lv_base_offset = lv_position - ls_entry-base_distance.
          READ TABLE lt_decoded INTO ls_base_decoded
            WITH KEY pack_offset = lv_base_offset.
          IF sy-subrc = 0.
            ls_base = ls_base_decoded-object.
            lv_delta_depth = ls_base_decoded-delta_depth + 1.
            lv_base_found = abap_true.
          ENDIF.
        ELSEIF ls_entry-type = 'ref-delta'.
          LOOP AT lt_decoded INTO ls_base_decoded.
            IF ls_base_decoded-object-key-oid = ls_entry-base_oid.
              ls_base = ls_base_decoded-object.
              lv_delta_depth = ls_base_decoded-delta_depth + 1.
              lv_base_found = abap_true.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF lv_base_found = abap_false AND mo_base_resolver IS NOT INITIAL.
            ls_base_key-repository_id = iv_repository_id.
            ls_base_key-algorithm = iv_algorithm.
            ls_base_key-oid = ls_entry-base_oid.
            ls_base = mo_base_resolver->read( ls_base_key ).
            IF ls_base-key-oid IS NOT INITIAL.
              lv_delta_depth = 1.
              lv_base_found = abap_true.
            ENDIF.
          ENDIF.
        ENDIF.
        IF lv_base_found = abap_false OR lv_delta_depth > iv_max_delta_depth.
          CLEAR rt_objects.
          RETURN.
        ENDIF.
        ls_object-type = ls_base-type.
        ls_object-payload = zcl_hithub_delta_codec=>apply(
          iv_base = ls_base-payload
          iv_delta = ls_stream-raw_data
          iv_delta_depth = lv_delta_depth
          iv_max_delta_depth = iv_max_delta_depth ).
        ls_object-size = xstrlen( ls_object-payload ).
      ENDIF.
      lv_oid = zcl_hithub_object_id=>calculate(
        iv_algorithm = iv_algorithm
        iv_type = ls_object-type
        iv_payload = ls_object-payload ).
      ls_object-key-oid = lv_oid.
      APPEND ls_object TO rt_objects.
      CLEAR ls_decoded.
      ls_decoded-object = ls_object.
      ls_decoded-pack_offset = lv_position.
      IF ls_entry-is_delta = abap_true.
        ls_decoded-delta_depth = lv_delta_depth.
      ENDIF.
      APPEND ls_decoded TO lt_decoded.
      lv_position = lv_compressed_offset + ls_stream-consumed_bytes.
    ENDDO.
    IF lv_position <> lv_body_length.
      CLEAR rt_objects.
    ENDIF.
  ENDMETHOD.

  METHOD repack.
    DATA ls_object TYPE zif_hithub_object_store=>ty_object.
    DATA lv_header TYPE xstring.
    DATA lv_entry_header TYPE xstring.
    DATA lv_compressed TYPE xstring.
    DATA lv_body TYPE xstring.
    DATA lv_digest TYPE xstring.
    DATA lv_oid TYPE string.

    CLEAR rv_pack.
    IF mo_compression IS INITIAL.
      RETURN.
    ENDIF.
    lv_header = zcl_hithub_pack_header=>build( lines( it_objects ) ).
    LOOP AT it_objects INTO ls_object.
      IF ls_object-type IS INITIAL
          OR ls_object-size <> xstrlen( ls_object-payload ).
        CLEAR rv_pack.
        RETURN.
      ENDIF.
      lv_entry_header = zcl_hithub_pack_entry=>build(
        iv_type = ls_object-type iv_size = ls_object-size ).
      IF lv_entry_header IS INITIAL.
        CLEAR rv_pack.
        RETURN.
      ENDIF.
      lv_compressed = mo_compression->compress( ls_object-payload ).
      IF lv_compressed IS INITIAL AND ls_object-payload IS NOT INITIAL.
        CLEAR rv_pack.
        RETURN.
      ENDIF.
      CONCATENATE lv_body lv_entry_header lv_compressed
        INTO lv_body IN BYTE MODE.
    ENDLOOP.
    CONCATENATE lv_header lv_body INTO rv_pack IN BYTE MODE.
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING
        if_algorithm = 'sha1'
        if_data = rv_pack
      IMPORTING
        ef_hashxstring = lv_digest ).
    CONCATENATE rv_pack lv_digest INTO rv_pack IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
