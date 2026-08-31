CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS advertises_safe_v0_v1_set FOR TESTING RAISING cx_static_check.
    METHODS advertises_receive_set FOR TESTING RAISING cx_static_check.
    METHODS renders_capabilities FOR TESTING RAISING cx_static_check.
    METHODS omits_empty_symref FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD advertises_safe_v0_v1_set.
    DATA lt_capabilities TYPE zcl_hithub_git_capabilities=>ty_capabilities.

    lt_capabilities = zcl_hithub_git_capabilities=>advertised(
      'refs/heads/main' ).
    ASSERT lines( lt_capabilities ) = 4.
    READ TABLE lt_capabilities WITH KEY table_line = 'no-thin'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'no-progress'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'symref=HEAD:refs/heads/main'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'agent=hithub'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'side-band-64k'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc <> 0.
  ENDMETHOD.

  METHOD advertises_receive_set.
    DATA lt_capabilities TYPE zcl_hithub_git_capabilities=>ty_capabilities.

    lt_capabilities = zcl_hithub_git_capabilities=>receive_advertised( ).
    ASSERT lines( lt_capabilities ) = 7.
    READ TABLE lt_capabilities WITH KEY table_line = 'report-status'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'side-band-64k'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'no-thin'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'delete-refs'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'ofs-delta'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'agent=hithub'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
    READ TABLE lt_capabilities WITH KEY table_line = 'object-format=sha1'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc = 0.
  ENDMETHOD.

  METHOD renders_capabilities.
    DATA lt_capabilities TYPE zcl_hithub_git_capabilities=>ty_capabilities.

    APPEND 'no-thin' TO lt_capabilities.
    APPEND 'agent=hithub' TO lt_capabilities.
    ASSERT zcl_hithub_git_capabilities=>render( lt_capabilities ) =
      'no-thin agent=hithub'.
  ENDMETHOD.

  METHOD omits_empty_symref.
    DATA lt_capabilities TYPE zcl_hithub_git_capabilities=>ty_capabilities.

    lt_capabilities = zcl_hithub_git_capabilities=>advertised( '' ).
    READ TABLE lt_capabilities WITH KEY table_line = 'symref=HEAD:'
      TRANSPORTING NO FIELDS.
    ASSERT sy-subrc <> 0.
  ENDMETHOD.

ENDCLASS.
