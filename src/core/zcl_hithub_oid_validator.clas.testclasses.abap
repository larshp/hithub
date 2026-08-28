CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS FINAL.

  PRIVATE SECTION.
    METHODS validates_supported_algorithms FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD validates_supported_algorithms.
    ASSERT zcl_hithub_oid_validator=>is_valid(
      iv_algorithm = 'sha1'
      iv_oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0' ) = abap_true.
    ASSERT zcl_hithub_oid_validator=>is_valid(
      iv_algorithm = 'sha1'
      iv_oid = 'B6FC4C620B67D95F953A5C1C1230AAAB5DB5A1B0' ) = abap_false.
    ASSERT zcl_hithub_oid_validator=>is_valid(
      iv_algorithm = 'sha1'
      iv_oid = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1' ) = abap_false.
    ASSERT zcl_hithub_oid_validator=>is_valid(
      iv_algorithm = 'md5'
      iv_oid = 'd41d8cd98f00b204e9800998ecf8427e' ) = abap_false.
  ENDMETHOD.

ENDCLASS.
