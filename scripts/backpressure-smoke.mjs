import {createGitAdmission} from "../server/git-admission.mjs";

const admission = createGitAdmission(2);
if (!admission.acquire() || !admission.acquire()
    || admission.acquire() || admission.active() !== 2) {
  throw new Error("Git admission did not apply its concurrency limit");
}
admission.release();
if (!admission.acquire() || admission.active() !== 2) {
  throw new Error("Git admission did not release capacity");
}
admission.release();
admission.release();
console.log("Git back-pressure smoke test passed");
