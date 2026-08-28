import {strict as assert} from "node:assert";
import {readFile} from "node:fs/promises";
import {test} from "node:test";
import {fileURLToPath} from "node:url";
import {join} from "node:path";

const fixtureRoot = fileURLToPath(new URL("./abapgit-fixture/", import.meta.url));

async function fixtureFile(relativePath) {
  return readFile(join(fixtureRoot, relativePath), "utf8");
}

test("abapGit fixture has a deserializable repository layout", async () => {
  const dotAbapGit = await fixtureFile(".abapgit.xml");
  const packageXml = await fixtureFile("src/package.devc.xml");
  const classXml = await fixtureFile("src/zcl_hithub_fixture.clas.xml");
  const classAbap = await fixtureFile("src/zcl_hithub_fixture.clas.abap");

  assert.match(dotAbapGit, /<STARTING_FOLDER>\/src\/<\/STARTING_FOLDER>/);
  assert.match(dotAbapGit, /<FOLDER_LOGIC>PREFIX<\/FOLDER_LOGIC>/);
  assert.match(packageXml, /serializer="LCL_OBJECT_DEVC"/);
  assert.match(classXml, /serializer="LCL_OBJECT_CLAS"/);
  assert.match(classXml, /<CLSNAME>ZCL_HITHUB_FIXTURE<\/CLSNAME>/);
  assert.match(classAbap, /CLASS zcl_hithub_fixture DEFINITION/);
  assert.match(classAbap, /CLASS zcl_hithub_fixture IMPLEMENTATION/);

  for (const content of [dotAbapGit, packageXml, classXml, classAbap]) {
    assert.equal(content.includes("\r"), false);
    assert.equal(content.endsWith("\n"), true);
  }
});
