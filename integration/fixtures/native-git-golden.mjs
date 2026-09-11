export const nativeGitGoldenFixtures = [
  {
    name: "empty-blob",
    type: "blob",
    payload: Buffer.alloc(0),
    headerHex: "626c6f62203000",
    oid: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",
  },
  {
    name: "text-blob",
    type: "blob",
    payload: Buffer.from("hello\n", "utf8"),
    headerHex: "626c6f62203600",
    oid: "ce013625030ba8dba906f756967f9e9ca394464a",
  },
  {
    name: "binary-blob",
    type: "blob",
    payload: Buffer.from([0x00, 0x01, 0x02, 0x7f, 0x80, 0xff]),
    headerHex: "626c6f62203600",
    oid: "ac0deae0c6de979e3136dcc6bdb1d07c58d37107",
  },
  {
    name: "unicode-blob",
    type: "blob",
    payload: Buffer.from("Hällo 🌍\n", "utf8"),
    headerHex: "626c6f6220313200",
    oid: "83d5089f5ae0d203e46984bbddffe11606382cf0",
  },
  {
    name: "large-blob",
    type: "blob",
    payload: Buffer.alloc(4096, 0x61),
    headerHex: "626c6f62203430393600",
    oid: "9d235ed07cd19811a6ceb342de82f190e49c9f68",
  },
];
