CLASS zcl_hithub_pack_entry DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_entry,
        type           TYPE string,
        size           TYPE int8,
        data_offset    TYPE i,
        base_oid       TYPE xstring,
        base_distance  TYPE int8,
        is_delta       TYPE abap_bool,
      END OF ty_entry.

    CLASS-METHODS parse
      IMPORTING
        iv_data      TYPE xstring
        iv_oid_length TYPE i DEFAULT 20
      RETURNING
        VALUE(rs_entry) TYPE ty_entry.

    CLASS-METHODS build
      IMPORTING
        iv_type TYPE string
        iv_size TYPE int8
      RETURNING
        VALUE(rv_data) TYPE xstring.

ENDCLASS.

CLASS zcl_hithub_pack_entry IMPLEMENTATION.

  METHOD build.
    CONSTANTS lc_continue TYPE i VALUE 128.
    DATA lv_type TYPE i.
    DATA lv_size TYPE int8.
    DATA lv_byte_value TYPE i.
    DATA lv_byte TYPE x LENGTH 1.

    CLEAR rv_data.
    IF iv_size < 0.
      RETURN.
    ENDIF.
    CASE iv_type.
      WHEN 'commit'.
        lv_type = 16.
      WHEN 'tree'.
        lv_type = 32.
      WHEN 'blob'.
        lv_type = 48.
      WHEN 'tag'.
        lv_type = 64.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    lv_size = iv_size.
    lv_byte_value = lv_type + lv_size MOD 16.
    IF lv_size >= 16.
      lv_byte_value = lv_byte_value + lc_continue.
    ENDIF.
    lv_byte = lv_byte_value.
    rv_data = lv_byte.
    lv_size = lv_size DIV 16.
    WHILE lv_size > 0.
      lv_byte_value = lv_size MOD 128.
      lv_size = lv_size DIV 128.
      IF lv_size > 0.
        lv_byte_value = lv_byte_value + lc_continue.
      ENDIF.
      lv_byte = lv_byte_value.
      CONCATENATE rv_data lv_byte INTO rv_data IN BYTE MODE.
    ENDWHILE.
  ENDMETHOD.

  METHOD parse.
    CONSTANTS lc_continue TYPE x LENGTH 1 VALUE '80'.
    CONSTANTS lc_type_mask TYPE x LENGTH 1 VALUE '70'.
    CONSTANTS lc_size_mask TYPE x LENGTH 1 VALUE '0F'.
    CONSTANTS lc_low_mask TYPE x LENGTH 1 VALUE '7F'.
    CONSTANTS lc_zero TYPE x LENGTH 1 VALUE '00'.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_bits TYPE x LENGTH 1.
    DATA lv_value TYPE i.
    DATA lv_factor TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_type TYPE i.
    DATA lv_size TYPE int8.
    DATA lv_distance TYPE int8.

    CLEAR rs_entry.
    IF xstrlen( iv_data ) = 0 OR iv_oid_length <= 0.
      RETURN.
    ENDIF.

    lv_offset = 0.
    lv_byte = iv_data+lv_offset(1).
    lv_bits = lv_byte BIT-AND lc_size_mask.
    lv_value = lv_bits.
    lv_size = lv_value.
    lv_factor = 16.
    WHILE lv_byte BIT-AND lc_continue <> lc_zero.
      lv_offset = lv_offset + 1.
      IF lv_offset >= xstrlen( iv_data ).
        CLEAR rs_entry.
        RETURN.
      ENDIF.
      lv_byte = iv_data+lv_offset(1).
      lv_bits = lv_byte BIT-AND lc_low_mask.
      lv_value = lv_bits.
      lv_size = lv_size + lv_value * lv_factor.
      lv_factor = lv_factor * 128.
    ENDWHILE.
    lv_offset = lv_offset + 1.

    lv_bits = iv_data+0(1) BIT-AND lc_type_mask.
    lv_type = lv_bits.
    CASE lv_type.
      WHEN 16.
        rs_entry-type = 'commit'.
      WHEN 32.
        rs_entry-type = 'tree'.
      WHEN 48.
        rs_entry-type = 'blob'.
      WHEN 64.
        rs_entry-type = 'tag'.
      WHEN 96.
        rs_entry-type = 'ofs-delta'.
        rs_entry-is_delta = abap_true.
      WHEN 112.
        rs_entry-type = 'ref-delta'.
        rs_entry-is_delta = abap_true.
      WHEN OTHERS.
        CLEAR rs_entry.
        RETURN.
    ENDCASE.
    rs_entry-size = lv_size.

    IF rs_entry-type = 'ref-delta'.
      IF xstrlen( iv_data ) < lv_offset + iv_oid_length.
        CLEAR rs_entry.
        RETURN.
      ENDIF.
      rs_entry-base_oid = iv_data+lv_offset(iv_oid_length).
      lv_offset = lv_offset + iv_oid_length.
    ELSEIF rs_entry-type = 'ofs-delta'.
      IF lv_offset >= xstrlen( iv_data ).
        CLEAR rs_entry.
        RETURN.
      ENDIF.
      lv_byte = iv_data+lv_offset(1).
      lv_bits = lv_byte BIT-AND lc_low_mask.
      lv_value = lv_bits.
      lv_distance = lv_value.
      WHILE lv_byte BIT-AND lc_continue <> lc_zero.
        lv_offset = lv_offset + 1.
        IF lv_offset >= xstrlen( iv_data ).
          CLEAR rs_entry.
          RETURN.
        ENDIF.
        lv_byte = iv_data+lv_offset(1).
        lv_bits = lv_byte BIT-AND lc_low_mask.
        lv_value = lv_bits.
        lv_distance = ( lv_distance + 1 ) * 128 + lv_value.
      ENDWHILE.
      lv_offset = lv_offset + 1.
      rs_entry-base_distance = lv_distance.
    ENDIF.

    rs_entry-data_offset = lv_offset.
  ENDMETHOD.

ENDCLASS.
