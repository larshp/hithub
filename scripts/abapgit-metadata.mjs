// abapGit installs an object only when its serialized metadata sits next to the
// source, so every class and interface needs a .clas.xml / .intf.xml, every
// package folder a package.devc.xml, and the repository root an .abapgit.xml.
// abaplint does not need any of it, which is how the whole set went missing
// without CI noticing. Run with --check in the verify pipeline to keep it so.
import {createHash} from "node:crypto";
import {readdir, readFile, writeFile} from "node:fs/promises";
import {join, relative} from "node:path";

const root = "src";
const master = "E";
const rootPackage = "ZHITHUB";

// MIME repository folder the browser assets are installed into. abapGit names
// an SMIM object after its LOIO GUID, so the GUID of each asset is derived from
// its URL to keep the file name, the URL and ZCL_HITHUB_SAP_ASSET_STORE in
// agreement. The folder object is the exception; see findMimeFolder.
const mimeFolder = "/SAP/PUBLIC/zhithub";
const sicfService = {
  name: "ZHITHUB",
  url: "/sap/zhithub/",
  handler: "ZCL_HITHUB_HTTP",
  text: "HitHub",
};
const mimeTypes = new Map(Object.entries({
  css: {type: "text/css", class: "M_TEXT_L"},
  html: {type: "text/html", class: "M_TEXT_L"},
  js: {type: "text/javascript", class: "M_APP_L"},
  json: {type: "application/json", class: "M_APP_L"},
  png: {type: "image/png", class: "M_APP_L"},
  svg: {type: "image/svg+xml", class: "M_APP_L"},
  txt: {type: "text/plain", class: "M_TEXT_L"},
}));

function mimeGuid(url) {
  return createHash("md5").update(url).digest("hex");
}

// Folder name -> package suffix and description. PREFIX folder logic derives the
// folder from the package name, so these have to agree with the directory tree.
const packages = {
  "": {name: rootPackage, text: "HitHub Git-compatible repository hosting"},
  core: {name: `${rootPackage}_CORE`, text: "HitHub domain and Git object model"},
  frontend: {
    name: `${rootPackage}_FRONTEND`,
    text: "HitHub browser UI MIME objects",
  },
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

function sicfDocument({name, url, handler, text}) {
  const originalName = name.toLowerCase();
  return document("LCL_OBJECT_SICF", `      <URL>${url}</URL>
      <ICFSERVICE>
        <ICF_NAME>${name}</ICF_NAME>
        <FALLTHRU>X</FALLTHRU>
        <ORIG_NAME>${originalName}</ORIG_NAME>
      </ICFSERVICE>
      <ICFDOCU>
        <ICF_NAME>${name}</ICF_NAME>
        <ICF_LANGU>${master}</ICF_LANGU>
        <ICF_DOCU>${text}</ICF_DOCU>
      </ICFDOCU>
      <ICFHANDLER_TABLE>
        <ICFHANDLER>
          <ICF_NAME>${name}</ICF_NAME>
          <ICFORDER>01</ICFORDER>
          <ICFTYP>A</ICFTYP>
          <ICFHANDLER>${handler}</ICFHANDLER>
        </ICFHANDLER>
      </ICFHANDLER_TABLE>`);
}

// abapGit creates the MIME folder from a serialized SMIM object of its own,
// and PUT on a file below a missing folder fails, so the folder has to ship.
// Its file name cannot be generated: SAP assigns the folder its own LOIO GUID
// on import and abapGit serializes it back under that name, so a URL-derived
// name would be a second object for the same folder. Require the object
// instead, and let whatever the system serialized stay as it is.
async function findMimeFolder(directory, url) {
  let entries;
  try {
    entries = await readdir(directory);
  } catch (_error) {
    return null;
  }
  for (const entry of entries.filter((name) => name.endsWith(".smim.xml"))) {
    const content = await readFile(join(directory, entry), "utf8");
    if (content.includes("<FOLDER>X</FOLDER>")
        && content.includes(`<URL>${url}</URL>`)) {
      return entry;
    }
  }
  return null;
}

// EXTRA carries the file name and mime type into SMIMPHF. Without it abapGit
// leaves whatever SDOK_MIMETYPE_GET derived from the URL extension in place.
function mimeFileDocument(url, fileName, definition) {
  return document("LCL_OBJECT_SMIM", `      <URL>${url}</URL>
      <CLASS>${definition.class}</CLASS>
      <EXTRA>
        <FILE_NAME>${fileName}</FILE_NAME>
        <MIMETYPE>${definition.type}</MIMETYPE>
      </EXTRA>`);
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
  // A SICF filename is a fixed 40-character object key: the lower-case
  // service name padded to 15 characters, then the first 25 SHA-1 characters
  // of its URL. The padding is significant to abapGit's substring mapper.
  const sicfHash = createHash("sha1").update(sicfService.url)
    .digest("hex").slice(0, 25);
  const sicfObjectName = sicfService.name.toLowerCase().padEnd(15, " ");
  expected.set(join(root, "http",
    `${sicfObjectName}${sicfHash}.sicf.xml`),
  sicfDocument(sicfService));
  for (const directory of [root, ...directories]) {
    const key = relative(root, directory).split("\\").join("/");
    const definition = packages[key];
    if (!definition) {
      throw new Error(`No package is declared for src/${key}; add it to scripts/abapgit-metadata.mjs`);
    }
    expected.set(join(directory, "package.devc.xml"), packageDocument(definition.text));
  }
  const sources = files.map((file) => file.split("\\").join("/"));
  const assets = sources.filter((file) => /\.smim\.[^/]+$/.test(file)
    && !file.endsWith(".smim.xml"));
  if (assets.length
      && (await findMimeFolder(join(root, "frontend"), mimeFolder)) === null) {
    throw new Error(`No SMIM object in ${root}/frontend declares folder ${mimeFolder}; abapGit cannot PUT the assets below a folder it does not create`);
  }
  for (const file of assets) {
    const fileName = file.replace(/^.*\.smim\./, "");
    const extension = fileName.replace(/^.*\./, "").toLowerCase();
    const definition = mimeTypes.get(extension);
    if (!definition) {
      throw new Error(`No mime type is declared for .${extension}; add it to scripts/abapgit-metadata.mjs`);
    }
    const url = `${mimeFolder}/${fileName}`;
    const guid = mimeGuid(url);
    const expectedName = `${guid}.smim.${fileName}`;
    if (!file.endsWith(`/${expectedName}`)) {
      throw new Error(`${file} has to be named ${expectedName}, the GUID abapGit derives from ${url}`);
    }
    expected.set(file.replace(`.smim.${fileName}`, ".smim.xml"),
      mimeFileDocument(url, fileName, definition));
  }
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
  // An SMIM object is identified by the URL it deserializes into, so that is
  // the line the check has to enforce.
  const url = content.match(/<URL>([^<]+)<\/URL>/)?.[1];
  if (url && !current.includes(`<URL>${url}</URL>`)) {
    missing.push(`${path} does not declare <URL>${url}</URL>`);
  }
  if (path.endsWith(".sicf.xml")) {
    const required = [
      `<ICF_NAME>${sicfService.name}</ICF_NAME>`,
      `<ORIG_NAME>${sicfService.name.toLowerCase()}</ORIG_NAME>`,
      "<FALLTHRU>X</FALLTHRU>",
      `<ICFHANDLER>${sicfService.handler}</ICFHANDLER>`,
    ];
    for (const element of required) {
      if (!current.includes(element)) {
        missing.push(`${path} does not declare ${element}`);
      }
    }
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
