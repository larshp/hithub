import {strict as assert} from "node:assert";
import {test} from "node:test";
import {gitProtocolTraces} from "./git-protocol-traces.mjs";

function decodePktLines(data) {
  const packets = [];
  let offset = 0;
  while (offset < data.length) {
    assert.ok(offset + 4 <= data.length, "truncated pkt-line header");
    const code = data.subarray(offset, offset + 4).toString("ascii");
    if (code === "0000" || code === "0001" || code === "0002") {
      packets.push({code, payload: Buffer.alloc(0)});
      offset += 4;
      continue;
    }
    const length = Number.parseInt(code, 16);
    assert.ok(length >= 4, "invalid pkt-line length");
    assert.ok(offset + length <= data.length, "truncated pkt-line payload");
    packets.push({
      code,
      payload: data.subarray(offset + 4, offset + length),
    });
    offset += length;
  }
  return packets;
}

test("captured v0 discovery uses the Smart HTTP preamble and flush", () => {
  const packets = decodePktLines(gitProtocolTraces.v0Discovery);

  assert.equal(packets[0].payload.toString(), "# service=git-upload-pack\n");
  assert.equal(packets[1].code, "0000");
  assert.match(packets[2].payload.toString(), /^42ecf4732921.* HEAD\0/);
  assert.match(packets[3].payload.toString(), /^9c28a102abf1.* refs\/heads\/feature\n$/);
  assert.equal(packets.at(-1).code, "0000");
});

test("captured v2 advertisement lists commands and terminates with flush", () => {
  const packets = decodePktLines(gitProtocolTraces.v2Advertisement);

  assert.deepEqual(
    packets.slice(0, -1).map(({payload}) => payload.toString()),
    ["version 2\n", "agent=hithub\n", "ls-refs\n", "fetch=shallow\n"],
  );
  assert.equal(packets.at(-1).code, "0000");
});
