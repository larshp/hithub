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

test("repository Code page passes automated accessibility checks", async ({page}, testInfo) => {
  const name = `accessible-${Date.now()}-${testInfo.workerIndex}`;
  const response = await page.request.post("/api/repos", {data: {name}});
  expect(response.status()).toBe(201);
  await expectAccessible(page, `/ui/repos/${name}`);
});

test("the open reference switcher passes automated accessibility checks", async ({page}, testInfo) => {
  const name = `accessible-refs-${Date.now()}-${testInfo.workerIndex}`;
  expect((await page.request.post("/api/repos", {data: {name}})).status()).toBe(201);
  await page.goto(`/ui/repos/${name}`);
  await page.locator(".ref-switcher-summary").click();
  await expect(page.getByLabel("Find or create a branch")).toBeVisible();
  const results = await new AxeBuilder({page}).analyze();
  expect(results.violations, "the open reference switcher has accessibility violations")
    .toEqual([]);
});

test("issue list and detail pages pass automated accessibility checks", async ({page}, testInfo) => {
  const name = `accessible-issues-${Date.now()}-${testInfo.workerIndex}`;
  expect((await page.request.post("/api/repos", {data: {name}})).status()).toBe(201);
  const created = await page.request.post(`/api/repos/${name}/issues`, {
    data: {title: "Accessible issue", body: "Issue details"},
  });
  expect(created.status()).toBe(201);
  const issue = await created.json();
  expect(issue.id).toBe("1");
  await expectAccessible(page, `/ui/repos/${name}/issues`);
  await expectAccessible(page, `/ui/repos/${name}/issues/${issue.id}`);
});

test("pull request creation page passes automated accessibility checks", async ({page}) => {
  await page.route("**/api/repos/accessibility/branches", async (route) => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([
      {name: "refs/heads/main", oid: "a".repeat(40)},
      {name: "refs/heads/feature", oid: "b".repeat(40)},
    ]),
  }));
  await expectAccessible(page, "/ui/repos/accessibility/pulls/new");
});
