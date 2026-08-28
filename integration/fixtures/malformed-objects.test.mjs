import {strict as assert} from "node:assert";
import {test} from "node:test";
import {malformedLooseObjectFixtures} from "./malformed-objects.mjs";

test("malformed loose-object fixtures remain explicit and non-empty", () => {
  assert.equal(malformedLooseObjectFixtures.length, 3);
  for (const fixture of malformedLooseObjectFixtures) {
    assert.ok(fixture.name);
    assert.ok(fixture.reason);
    assert.match(fixture.rawHex, /^[0-9a-f]+$/);
    assert.ok(fixture.rawHex.length > 0);
  }
});
