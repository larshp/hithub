import AxeBuilder from "@axe-core/playwright";
import {expect, test} from "@playwright/test";

async function expectAccessible(page, url) {
  await page.goto(url);
  const results = await new AxeBuilder({page}).analyze();
  expect(results.violations, `${url} has accessibility violations`).toEqual([]);
}

test("home page passes automated accessibility checks", async ({page}) => {
  await expectAccessible(page, "/");
});

test("repository creation page passes automated accessibility checks", async ({page}) => {
  await expectAccessible(page, "/ui/create");
});
