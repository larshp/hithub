// Adjusts the JavaScript environment the transpiled ABAP runtime expects.
//
// preview-backend.mjs imports this first, and the module graph is evaluated in
// import order, so everything below is in place before the runtime is loaded.
import {PREVIEW_INSTANT} from "./preview-instant.mjs";

// The generated CL_SYSTEM_UUID reaches for window.crypto, because the runtime
// was written for a page. A service worker has the same crypto object on its
// own global, under a different name.
globalThis.window ??= globalThis;

// GET TIME STAMP reaches the JavaScript Date, so replacing Date is what pins
// the timestamps the preview writes.
const RealDate = Date;

class PreviewDate extends RealDate {
  constructor(...args) {
    if (args.length === 0) {
      super(PREVIEW_INSTANT);
      return;
    }
    super(...args);
  }

  static now() {
    return PREVIEW_INSTANT;
  }
}

globalThis.Date = PreviewDate;
