import {existsSync, readFileSync} from "node:fs";
import {resolve} from "node:path";

const root = process.cwd();
const source = readFileSync(resolve(root, "ANORMALIES.md"), "utf8");
const sections = source.split(/^### /m).slice(1);
let checked = 0;

for (const section of sections) {
  const heading = section.split("\n", 1)[0];
  if (!heading.startsWith("ANOMALY-") || heading.includes("YYYY-MM-DD")) {
    continue;
  }
  const match = section.match(/^- Regression-test location: (.+)$/m);
  if (!match || !match[1].trim()) {
    throw new Error(`${heading}: missing regression-test location`);
  }
  const location = match[1].trim().replaceAll("`", "");
  if (!existsSync(resolve(root, location))) {
    throw new Error(`${heading}: regression test does not exist: ${location}`);
  }
  checked += 1;
}

console.log(`Anomaly regression references verified: ${checked}`);
