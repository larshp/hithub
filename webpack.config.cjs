const path = require("node:path");
const webpack = require("webpack");
const TerserPlugin = require("terser-webpack-plugin");

// Bundles the transpiled ABAP application into the service worker that serves
// the preview deployment. scripts/build-preview.mjs runs it; see
// docs/preview-deployments.md for what the preview is and how it is deployed.
module.exports = {
  mode: "production",
  // The preview has no server, so the application runs where the requests are
  // intercepted: in the service worker.
  target: "webworker",
  entry: path.resolve(__dirname, "web/preview-worker.mjs"),
  output: {
    path: path.resolve(__dirname, "build"),
    filename: "sw.js",
    clean: true,
  },
  devtool: false,
  experiments: {
    // The generated runtime awaits its module graph at the top level.
    topLevelAwait: true,
  },
  performance: {
    // The bundle carries a database engine and an ABAP runtime. Warning about
    // its size on every build says nothing that is not already known.
    hints: false,
  },
  optimization: {
    minimize: true,
    minimizer: [
      new TerserPlugin({
        extractComments: false,
        terserOptions: {
          // The generated code looks classes up by name at runtime.
          keep_classnames: true,
          keep_fnames: true,
          mangle: {keep_classnames: true, keep_fnames: true},
        },
      }),
    ],
  },
  resolve: {
    extensions: [".mjs", ".js"],
    alias: {
      // The WebAssembly build fetches its own .wasm file, which would be one
      // more thing to deploy and one more request to route around the worker.
      "sql.js$": require.resolve("sql.js/dist/sql-asm.js"),
    },
    // The generated code reaches for the Node standard library. The browser
    // implementations answer the same calls; the ones set to false are only
    // referenced by paths the preview never takes.
    fallback: {
      assert: require.resolve("assert/"),
      buffer: require.resolve("buffer/"),
      constants: require.resolve("constants-browserify"),
      crypto: require.resolve("crypto-browserify"),
      events: require.resolve("events/"),
      http: require.resolve("stream-http"),
      https: require.resolve("https-browserify"),
      os: require.resolve("os-browserify/browser"),
      path: require.resolve("path-browserify"),
      process: require.resolve("process/browser"),
      stream: require.resolve("stream-browserify"),
      string_decoder: require.resolve("string_decoder/"),
      url: require.resolve("url/"),
      util: require.resolve("util/"),
      vm: require.resolve("vm-browserify"),
      zlib: require.resolve("browserify-zlib"),
      fs: false,
      net: false,
      tls: false,
    },
  },
  module: {
    rules: [
      {
        test: /\.m?js$/,
        resolve: {fullySpecified: false},
      },
    ],
  },
  plugins: [
    // "node:fs" is a URI scheme to webpack rather than a module request, so it
    // never reaches the fallbacks above. sql.js asks for its Node dependencies
    // that way; strip the prefix and let them resolve like every other one.
    new webpack.NormalModuleReplacementPlugin(/^node:/, (resource) => {
      resource.request = resource.request.replace(/^node:/, "");
    }),
    // The transpiler escapes the namespace in /ui2/cl_json when it writes the
    // import, and the escaped name is not a file on disk.
    new webpack.NormalModuleReplacementPlugin(
      /%23ui2%23cl_json\.clas(?:\.locals)?\.mjs$/,
      (resource) => {
        const filename = resource.request
          .replace(/^\.\//, "")
          .replaceAll("%23ui2%23", "#ui2#");
        resource.request = path.resolve(__dirname, "output", filename);
      },
    ),
    new webpack.ProvidePlugin({
      Buffer: ["buffer", "Buffer"],
      process: "process/browser",
    }),
    // The generated runtime imports every ABAP object dynamically. Keeping one
    // chunk means the worker is a single self-contained script, which is what
    // the service worker registration expects.
    new webpack.optimize.LimitChunkCountPlugin({maxChunks: 1}),
  ],
};
