export const malformedLooseObjectFixtures = [
  {
    name: "missing-header-terminator",
    rawHex: "626c6f622031",
    reason: "object header has no NUL terminator",
  },
  {
    name: "non-numeric-size",
    rawHex: "626c6f62207800",
    reason: "object header size is not decimal",
  },
  {
    name: "payload-size-mismatch",
    rawHex: "626c6f6220320078",
    reason: "header size does not match payload length",
  },
];
