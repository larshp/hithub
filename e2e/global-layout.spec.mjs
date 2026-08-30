import {expect, test} from "@playwright/test";

test("global repository shell loads", async ({page}) => {
  await page.goto("/");
  await expect(page).toHaveTitle("HitHub");
  await expect(page.locator("#main-content")).toBeVisible();
  await expect(page.locator(".skip-link")).toHaveText("Skip to main content");
  await expect(page.getByRole("banner")).toBeVisible();
  await expect(page.getByRole("navigation", {name: "Primary navigation"})).toBeVisible();
  await expect(page.getByRole("search")).toBeVisible();
  await expect(page.getByRole("link", {name: "New repository"})).toHaveCount(1);
  await expect(page.getByRole("main")).toBeVisible();
  await expect(page.getByRole("contentinfo")).toBeVisible();
  await page.keyboard.press("Tab");
  await expect(page.locator(".skip-link")).toBeFocused();
});

test("global shell remains usable on a narrow viewport", async ({page}) => {
  await page.setViewportSize({width: 390, height: 844});
  await page.goto("/");
  await expect(page.locator(".page-intro").getByRole("link", {name: "New repository"})).toBeVisible();
  await page.getByRole("button", {name: "Open navigation"}).click();
  await expect(page.getByRole("navigation", {name: "Primary navigation"})).toBeVisible();
  const fitsViewport = await page.evaluate(
    () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
  );
  expect(fitsViewport).toBe(true);
});

test("global search filters the repository index", async ({page}) => {
  await page.route("**/api/repos", async (route) => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([
      {name: "alpha", description: "First repository", default_branch: "main", version: 1},
      {name: "beta", description: "Second repository", default_branch: "main", version: 1},
    ]),
  }));
  await page.goto("/?q=alpha");
  await expect(page.locator(".repository-row")).toHaveCount(1);
  await expect(page.getByRole("link", {name: "alpha"})).toBeVisible();
  await expect(page.getByRole("link", {name: "beta"})).toHaveCount(0);
  await expect(page.locator(".repository-row")).toContainText("Default branch main");
  await expect(page.locator("#service-status, #header-status")).toHaveCount(0);
});
