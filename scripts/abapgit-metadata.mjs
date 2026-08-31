// abapGit installs an object only when its serialized metadata sits next to the
// source, so every class and interface needs a .clas.xml / .intf.xml, every
// package folder a package.devc.xml, and the repository root an .abapgit.xml.
// abaplint does not need any of it, which is how the whole set went missing
// without CI noticing. Run with --check in the verify pipeline to keep it so.
import {readdir, readFile, writeFile} from "node:fs/promises";
import {join, relative} from "node:path";

const root = "src";
const master = "E";
const rootPackage = "ZHITHUB";

// Folder name -> package suffix and description. PREFIX folder logic derives the
// folder from the package name, so these have to agree with the directory tree.
const packages = {
  "": {name: rootPackage, text: "HitHub Git-compatible repository hosting"},
  core: {name: `${rootPackage}_CORE`, text: "HitHub domain and Git object model"},
  http: {name: `${rootPackage}_HTTP`, text: "HitHub ICF handler and REST routes"},
  infrastructure: {
    name: `${rootPackage}_INFRA`,
    text: "HitHub persistence adapters",
  },
  "infrastructure/local": {
    name: `${rootPackage}_INFRA_LOCAL`,
    text: "HitHub open-abap persistence adapters",
  },
  "infrastructure/sap": {
    name: `${rootPackage}_INFRA_SAP`,
    text: "HitHub SAP persistence adapters",
  },
  persistence: {
    name: `${rootPackage}_PERSISTENCE`,
    text: "HitHub DDIC artifacts",
  },
};

// Words that must not be title-cased when a name is turned into a description.
const abbreviations = new Map(Object.entries({
  abap: "ABAP", api: "API", ddic: "DDIC", gc: "GC", http: "HTTP", icf: "ICF",
  id: "ID", json: "JSON", oid: "OID", ofs: "OFS", pr: "PR", ref: "ref",
  refs: "refs", repo: "repository", repr: "representation", rest: "REST",
  sap: "SAP", sha1: "SHA-1", uuid: "UUID", v2: "v2", adler32: "Adler-32",
}));

function describe(objectName) {
  const words = objectName.toLowerCase()
    .replace(/^z(cl|if)_hithub_?/, "")
    .split("_")
    .filter(Boolean)
    .map((word) => abbreviations.get(word) || word);
  if (!words.length) return "HitHub";
  const text = `HitHub ${words.join(" ")}`;
  // VSEOCLASS-DESCRIPT and VSEOINTERF-DESCRIPT hold 60 characters.
  return text.length > 60 ? `${text.slice(0, 57)}...` : text;
}

function document(serializer, body) {
  return `<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="${serializer}" serializer_version="v1.0.0">
  <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
    <asx:values>
${body}
    </asx:values>
  </asx:abap>
</abapGit>
`;
}

function classDocument(name, hasTests) {
  // CLSCCINCL and WITH_UNIT_TESTS both have to be set for a class whose test
  // include is serialized, otherwise abapGit drops the .clas.testclasses.abap
  // file on import and abaplint's local_testclass_consistency rule complains.
  const tests = hasTests
    ? `        <CLSCCINCL>X</CLSCCINCL>
        <FIXPT>X</FIXPT>
        <UNICODE>X</UNICODE>
        <WITH_UNIT_TESTS>X</WITH_UNIT_TESTS>`
    : `        <CLSCCINCL></CLSCCINCL>
        <FIXPT>X</FIXPT>
        <UNICODE>X</UNICODE>`;
  return document("LCL_OBJECT_CLAS", `      <VSEOCLASS>
        <CLSNAME>${name}</CLSNAME>
        <LANGU>${master}</LANGU>
        <DESCRIPT>${describe(name)}</DESCRIPT>
        <STATE>1</STATE>
${tests}
      </VSEOCLASS>`);
}

function interfaceDocument(name) {
  return document("LCL_OBJECT_INTF", `      <VSEOINTERF>
        <CLSNAME>${name}</CLSNAME>
        <LANGU>${master}</LANGU>
        <DESCRIPT>${describe(name)}</DESCRIPT>
        <EXPOSURE>2</EXPOSURE>
        <STATE>1</STATE>
        <UNICODE>X</UNICODE>
      </VSEOINTERF>`);
}

function packageDocument(text) {
  return document("LCL_OBJECT_DEVC", `      <DEVC>
        <CTEXT>${text}</CTEXT>
      </DEVC>`);
}

const repositoryDocument = `<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0">
  <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
    <asx:values>
      <DATA>
        <MASTER_LANGUAGE>${master}</MASTER_LANGUAGE>
        <STARTING_FOLDER>/${root}/</STARTING_FOLDER>
        <FOLDER_LOGIC>PREFIX</FOLDER_LOGIC>
        <IGNORE>
          <item>/.gitignore</item>
          <item>/LICENSE</item>
          <item>/*.md</item>
          <item>/*.json</item>
          <item>/*.jsonc</item>
          <item>/*.mjs</item>
        </IGNORE>
      </DATA>
    </asx:values>
  </asx:abap>
</abapGit>
`;

async function walk(directory) {
  const entries = await readdir(directory, {withFileTypes: true});
  const files = [];
  const directories = [];
  for (const entry of entries) {
    if (entry.isDirectory()) directories.push(join(directory, entry.name));
    else files.push(join(directory, entry.name));
  }
  for (const child of directories) {
    const nested = await walk(child);
    files.push(...nested.files);
    directories.push(...nested.directories);
  }
  return {files, directories};
}

export async function collect() {
  const {files, directories} = await walk(root);
  const expected = new Map();
  expected.set(".abapgit.xml", repositoryDocument);
  for (const directory of [root, ...directories]) {
    const key = relative(root, directory).split("\\").join("/");
    const definition = packages[key];
    if (!definition) {
      throw new Error(`No package is declared for src/${key}; add it to scripts/abapgit-metadata.mjs`);
    }
    expected.set(join(directory, "package.devc.xml"), packageDocument(definition.text));
  }
  const sources = files.map((file) => file.split("\\").join("/"));
  for (const file of sources) {
    const classMatch = file.match(/\/(z[a-z0-9_]+)\.clas\.abap$/);
    if (classMatch) {
      const name = classMatch[1].toUpperCase();
      const hasTests = sources.includes(file.replace(/\.clas\.abap$/, ".clas.testclasses.abap"));
      expected.set(file.replace(/\.clas\.abap$/, ".clas.xml"), classDocument(name, hasTests));
      continue;
    }
    const interfaceMatch = file.match(/\/(z[a-z0-9_]+)\.intf\.abap$/);
    if (interfaceMatch) {
      const name = interfaceMatch[1].toUpperCase();
      expected.set(file.replace(/\.intf\.abap$/, ".intf.xml"), interfaceDocument(name));
    }
  }
  return expected;
}

const check = process.argv.includes("--check");
const expected = await collect();
const missing = [];
const written = [];

for (const [path, content] of expected) {
  let current = null;
  try {
    current = await readFile(path, "utf8");
  } catch (_error) {
    current = null;
  }
  if (current === null) {
    if (check) missing.push(`${path} is missing`);
    else {
      await writeFile(path, content, "utf8");
      written.push(path);
    }
    continue;
  }
  // Descriptions are meant to be improved by hand, so only the identity that
  // abapGit needs to create the object is enforced.
  const name = path.match(/([a-z0-9_]+)\.(clas|intf)\.xml$/)?.[1]?.toUpperCase();
  if (name && !current.includes(`<CLSNAME>${name}</CLSNAME>`)) {
    missing.push(`${path} does not declare <CLSNAME>${name}</CLSNAME>`);
  }
}

if (check) {
  if (missing.length) {
    console.error(`abapGit metadata is incomplete:\n  ${missing.join("\n  ")}`);
    process.exit(1);
  }
  console.log(`abapGit metadata verified: ${expected.size} serialized objects`);
} else {
  console.log(written.length
    ? `abapGit metadata written: ${written.length} file(s)`
    : `abapGit metadata already complete: ${expected.size} serialized objects`);
}
