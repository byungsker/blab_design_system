import { expect, test } from "@playwright/test";

test("renders the standalone fixture across target viewports", async ({ page }) => {
  const pageErrors: string[] = [];
  const failedRequests: string[] = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("requestfailed", (request) => failedRequests.push(`${request.url()} ${request.failure()?.errorText ?? "unknown"}`));

  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/fixture/index.html?theme=dark", { waitUntil: "networkidle" });

  const fixture = page.locator('[data-blab-component="parity-fixture"]');
  await expect(fixture).toBeVisible();
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(18, 18, 18)");
  await expect(page.getByRole("button", { name: "Primary action" })).toBeVisible();
  await expect(page.getByRole("status").first()).toBeVisible();
  await expect(page.getByRole("navigation", { name: "Keyboard accessory" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Move up" })).toBeEnabled();
  await expect(page.getByRole("button", { name: "Undo" })).toBeEnabled();
  await expect(page.getByRole("button", { name: "Done" })).toBeEnabled();

  const primaryButton = page.getByRole("button", { name: "Primary action" });
  await primaryButton.focus();
  await expect(primaryButton).toBeFocused();

  await page.emulateMedia({ reducedMotion: "reduce" });
  const transitionDurationInSeconds = await primaryButton.evaluate((element) =>
    Number.parseFloat(getComputedStyle(element).transitionDuration),
  );
  expect(transitionDurationInSeconds).toBeGreaterThan(0);
  expect(transitionDurationInSeconds).toBeLessThanOrEqual(0.00001);

  await page.setViewportSize({ width: 1440, height: 900 });
  await expect(fixture).toBeVisible();
  await page.goto("/fixture/index.html?theme=light", { waitUntil: "networkidle" });
  await expect(fixture).toHaveAttribute("data-blab-theme", "light");
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(250, 250, 250)");
  await expect(page.getByRole("button", { name: "Primary action" })).toBeVisible();
  expect(pageErrors).toEqual([]);
  expect(failedRequests).toEqual([]);
});
