// Diagnostic runner: same loop as the generated output/index.mjs, but it keeps
// going after a failing test method so one pass lists every failure.
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

const failures = [];
let passed = 0;

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
    const name = `${objectName}: ${localClassName}->${m.name}`;
    try {
      const test = await (new localClass()).constructor_();
      if (test.setup) {
        await test.setup();
      }
      if (test.FRIENDS_ACCESS_INSTANCE.setup) {
        await test.FRIENDS_ACCESS_INSTANCE.setup();
      }
      await test.FRIENDS_ACCESS_INSTANCE[m.name]();
      if (test.teardown) {
        await test.teardown();
      }
      if (test.FRIENDS_ACCESS_INSTANCE.teardown) {
        await test.FRIENDS_ACCESS_INSTANCE.teardown();
      }
      passed += 1;
    } catch (err) {
      const detail = err?.msg?.value
        || `expected [${err?.expected?.value}] actual [${err?.actual?.value}]`;
      const where = err?.stack?.split("\n")[1]?.trim() ?? "";
      failures.push(`${name}\n    ${detail}\n    ${where}`);
    }
  }
  if (localClass.class_teardown) {
    await localClass.class_teardown();
  }
}

console.log(`\npassed: ${passed}, failed: ${failures.length}`);
for (const failure of failures) {
  console.log("  " + failure);
}
process.exit(failures.length === 0 ? 0 : 1);
