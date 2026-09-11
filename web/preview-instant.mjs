// The instant the preview deployment runs at.
//
// The preview seeds its own repositories on every boot, so without a pinned
// clock every issue, commit and pull request would carry the wall clock of the
// deployment run, and every screenshot comparison against main would report a
// difference that is only a timestamp. web/preview-runtime.mjs pins the ABAP
// runtime to this instant and scripts/capture-web-screenshots.mjs pins the
// browser to the same one, so relative timestamps render identically on every
// run.
export const PREVIEW_INSTANT = Date.UTC(2026, 0, 1, 9, 0, 0);
