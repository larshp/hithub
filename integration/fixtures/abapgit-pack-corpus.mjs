// Standard Git pack bytes for the smallest abapGit-compatible object corpus.
// The vector is checked against the reviewed abapGit pack codec revision in
// docs/abapgit-pack-delta-review.md; production code does not depend on it.
export const abapGitPackCorpus = [
  {
    name: "single-blob-v2",
    packHex: "5041434b000000020000000136789c4bcac94f523063c848cdc9c9e702001dc50414c32aba73bdeef306abca597b61b1fe3e349320e4",
    objectType: "blob",
    objectId: "ce013625030ba8dba906f756967f9e9ca394464a",
    objectPayload: Buffer.from("hello\n", "utf8"),
  },
];
