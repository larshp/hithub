const {initializeABAP} = await import("../build/spikes/open-abap-transport/init.mjs");

await initializeABAP();

const exitClass = abap.Classes["ZCL_ABAPGIT_EXIT"];
const exit = new abap.types.ABAPObject({
  qualifiedName: "ZIF_ABAPGIT_EXIT",
  RTTIName: "\\INTERFACE=ZIF_ABAPGIT_EXIT",
});
exit.set(new exitClass());
exitClass.get_instance = async () => exit;

abap.Classes["ZCL_ABAPGIT_HTTP"].get_connection_longtext = async () =>
  new abap.types.String();

const transport = abap.Classes["ZCL_ABAPGIT_GIT_TRANSPORT"];
const url = "http://127.0.0.1:3000/branches.git";

await transport.upload_pack_by_commit({
  iv_url: url,
  iv_hash: "42ecf4732921edb931da28ec3c50b77ee43f5176",
});
console.log("abapGit clone: main commit fetched");

await transport.upload_pack_by_commit({
  iv_url: url,
  iv_hash: "9c28a102abf1b9117361c106846316d4322a9fdf",
});
console.log("abapGit pull: feature commit fetched");

await transport.receive_pack({
  iv_url: url,
  iv_old: "0000000000000000000000000000000000000000",
  iv_new: "42ecf4732921edb931da28ec3c50b77ee43f5176",
  iv_branch_name: "refs/heads/abapgit-check",
});
console.log("abapGit push: branch created");

await transport.receive_pack({
  iv_url: url,
  iv_old: "42ecf4732921edb931da28ec3c50b77ee43f5176",
  iv_new: "0000000000000000000000000000000000000000",
  iv_branch_name: "refs/heads/abapgit-check",
});
console.log("abapGit push: branch deleted");
