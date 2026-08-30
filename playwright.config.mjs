import {defineConfig, devices} from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: {timeout: 5_000},
  fullyParallel: true,
  reporter: "list",
  use: {
    baseURL: "http://127.0.0.1:3600",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "off",
  },
  projects: [
    {name: "chromium", use: {...devices["Desktop Chrome"]}},
    {name: "firefox", use: {...devices["Desktop Firefox"]}},
  ],
  webServer: {
    command: "node server/index.mjs",
    url: "http://127.0.0.1:3600/health",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
    env: {
      ...process.env,
      HITHUB_PORT: "3600",
      HITHUB_FIXTURE_REPOSITORY: "compare-fixture",
      // Parallel browsers share one client address, so the default per-address
      // budget throttles the harness itself. scripts/limits-smoke.mjs covers
      // the rate limiter; here it only needs to stay out of the way.
      HITHUB_RATE_LIMIT: "5000",
    },
  },
});
