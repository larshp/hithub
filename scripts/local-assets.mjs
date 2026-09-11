// The browser assets are abapGit SMIM objects in src/frontend, so an installed
// service reads them from the MIME repository. The local open-abap runtime has
// no MIME repository, so it registers the same bytes - read from the same
// serialized files, described by the same metadata - into
// ZCL_HITHUB_LOCAL_ASSET_STORE during startup. This module is the only place
// that knows the abapGit SMIM file layout on the Node side.
import {readdir, readFile} from "node:fs/promises";
import {join} from "node:path";

export async function readSerializedAssets(directory) {
  const entries = await readdir(directory);
  const assets = [];
  for (const entry of entries.filter((name) => name.endsWith(".smim.xml"))) {
    const metadata = await readFile(join(directory, entry), "utf8");
    // The folder object carries no data file; it only makes abapGit create
    // the MIME folder the assets are installed into.
    if (metadata.includes("<FOLDER>X</FOLDER>")) continue;
    const name = metadata.match(/<FILE_NAME>([^<]+)<\/FILE_NAME>/)?.[1];
    const mimeType = metadata.match(/<MIMETYPE>([^<]+)<\/MIMETYPE>/)?.[1];
    if (!name || !mimeType) {
      throw new Error(`${entry} does not serialize a file name and mime type`);
    }
    const data = await readFile(
      join(directory, entry.replace(/\.smim\.xml$/, `.smim.${name}`)),
    );
    assets.push({name, mimeType, content: data.toString("base64")});
  }
  if (!assets.length) {
    throw new Error(`${directory} serializes no browser assets`);
  }
  return assets.sort((left, right) => left.name.localeCompare(right.name));
}
