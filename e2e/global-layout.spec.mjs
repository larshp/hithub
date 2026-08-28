import {expect, test} from "@playwright/test";

test("global repository shell loads", async ({page}) => {
  await page.goto("/");
  await expect(page).toHaveTitle("HitHub");
  await expect(page.locator("#main-content")).toBeVisible();
  await expect(page.locator(".skip-link")).toHaveText("Skip to main content");
  await expect(page.getByRole("banner")).toBeVisible();
  await expect(page.getByRole("navigation", {name: "Primary navigation"})).toBeVisible();
  await expect(page.getByRole("main")).toBeVisible();
  await expect(page.getByRole("contentinfo")).toBeVisible();
  await page.keyboard.press("Tab");
  await expect(page.locator(".skip-link")).toBeFocused();
});

test("global shell remains usable on a narrow viewport", async ({page}) => {
  await page.setViewportSize({width: 390, height: 844});
  await page.goto("/");
  await expect(page.getByRole("link", {name: "Create repository"})).toBeVisible();
  const fitsViewport = await page.evaluate(
    () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
  );
  expect(fitsViewport).toBe(true);
});
