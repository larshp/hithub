import express from "express";
import {initializeABAP} from "../build/transpiled/init.mjs";
import {cl_express_icf_shim} from "../build/transpiled/cl_express_icf_shim.clas.mjs";

await initializeABAP();

const app = express();
const port = Number(process.env.HITHUB_PORT || 3000);

app.use(express.raw({type: "*/*"}));

app.all(["/health", "/health/*"], async (req, res) => {
  await cl_express_icf_shim.run({
    req,
    res,
    class: "ZCL_HITHUB_HTTP",
  });
});

app.listen(port, "127.0.0.1", () => {
  console.log(`HitHub listening on http://127.0.0.1:${port}`);
});
