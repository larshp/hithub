// Diagnostic runner: same loop as the generated output/index.mjs, but it keeps
// going after a failing test method so one pass lists every failure.
//
// "--repeat N" runs the whole suite N times against the same database. A real
// SAP system keeps whatever a test commits, so a second pass is what catches a
// fixture that only works on an empty database.
import {readFileSync} from "node:fs";
import {createLocalDatabase} from "./local-database.mjs";

const generated = readFileSync("output/init.mjs", "utf8");
const tick = String.fromCharCode(96);
const statements = generated.split("\n")
  .filter((line) => line.includes("sqlite.push("))
  .map((line) => line.slice(line.indexOf(tick) + 1, line.lastIndexOf(tick)));

await import("../output/init.mjs");
globalThis.abap.context.databaseConnections.DEFAULT =
  await createLocalDatabase(statements);

const source = readFileSync("output/index.mjs", "utf8");
const entries = [...source.matchAll(
  /ret\.push\(\{objectName: "(.+?)",\s*localClass: "(.+?)",\s*methods: (\[.*?\]),\s*riskLevel: "(.+?)",\s*filename: "(.+?)"\}\);/gs)];

const repeatIndex = process.argv.indexOf("--repeat");
const repeat = repeatIndex === -1 ? 1 : Number(process.argv[repeatIndex + 1]);

const failures = [];
let passed = 0;

for (let pass = 1; pass <= repeat; pass += 1) {
  for (const [, objectName, localClassName, methodsJson, , filename] of entries) {
    const imported = await import("../output/" + filename.replace("./", ""));
    const localClass = imported[localClassName];
    if (localClass.class_setup) {
      await localClass.class_setup();
    }
    for (const m of JSON.parse(methodsJson)) {
      if (m.skip) {
        continue;
      }
      const name = repeat === 1
        ? `${objectName}: ${localClassName}->${m.name}`
        : `pass ${pass} ${objectName}: ${localClassName}->${m.name}`;
      let test;
      try {
        test = await (new localClass()).constructor_();
        if (test.setup) {
          await test.setup();
        }
        if (test.FRIENDS_ACCESS_INSTANCE.setup) {
          await test.FRIENDS_ACCESS_INSTANCE.setup();
        }
        await test.FRIENDS_ACCESS_INSTANCE[m.name]();
        passed += 1;
      } catch (err) {
        const detail = err?.msg?.value
          || `expected [${err?.expected?.value}] actual [${err?.actual?.value}]`;
        const where = err?.stack?.split("\n")[1]?.trim() ?? "";
        failures.push(`${name}\n    ${detail}\n    ${where}`);
      }
      // ABAP Unit runs teardown even when the test method failed, and the
      // teardowns here are what clear committed fixtures.
      try {
        if (test?.teardown) {
          await test.teardown();
        }
        if (test?.FRIENDS_ACCESS_INSTANCE.teardown) {
          await test.FRIENDS_ACCESS_INSTANCE.teardown();
        }
      } catch (err) {
        failures.push(`${name} (teardown)\n    ${err?.message ?? err}`);
      }
      // ABAP Unit rolls back after every test method, so only what a test
      // committed reaches the next one. The generated runner does not, and
      // without this a repeated pass would see uncommitted writes too.
      await globalThis.abap.statements.rollback();
    }
    if (localClass.class_teardown) {
      await localClass.class_teardown();
    }
  }
}

console.log(`\npasses: ${repeat}, passed: ${passed}, failed: ${failures.length}`);
for (const failure of failures) {
  console.log("  " + failure);
}
process.exit(failures.length === 0 ? 0 : 1);
