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
  const accessorySurface = page.locator(".blab-keyboard-accessory-bar__surface");
  await expect(accessorySurface).toHaveCSS("overflow-x", "auto");
  const accessoryDimensions = await accessorySurface.evaluate((element) => ({
    clientWidth: element.clientWidth,
    scrollWidth: element.scrollWidth,
  }));
  expect(accessoryDimensions.scrollWidth).toBeGreaterThan(accessoryDimensions.clientWidth);
  await expect(page).toHaveScreenshot("dark-mobile.png", { animations: "disabled" });
  await accessorySurface.evaluate((element) => {
    element.scrollLeft = element.scrollWidth;
  });
  await expect(page.getByRole("button", { name: "Done" })).toBeInViewport();

  const primaryButton = page.getByRole("button", { name: "Primary action" });
  await primaryButton.focus();
  await expect(primaryButton).toBeFocused();

  await page.emulateMedia({ reducedMotion: "reduce" });
  const transitionDurationInSeconds = await primaryButton.evaluate((element) =>
    Number.parseFloat(getComputedStyle(element).transitionDuration),
  );
  expect(transitionDurationInSeconds).toBeGreaterThan(0);
  expect(transitionDurationInSeconds).toBeLessThanOrEqual(0.00001);

  const firstTab = page.getByRole("tab", { name: "First" });
  const secondTab = page.getByRole("tab", { name: "Second" });
  await firstTab.focus();
  await firstTab.press("ArrowRight");
  await expect(secondTab).toBeFocused();

  const segments = page.getByRole("group", { name: "Fixture segments" });
  const firstSegment = segments.getByRole("button", { name: "First" });
  const secondSegment = segments.getByRole("button", { name: "Second" });
  await firstSegment.focus();
  await firstSegment.press("ArrowRight");
  await expect(secondSegment).toBeFocused();

  await page.evaluate(() => {
    const probe = document.createElement("div");
    probe.id = "external-motion-probe";
    probe.style.transitionDuration = "2s";
    document.body.append(probe);
  });
  await expect(page.locator("#external-motion-probe")).toHaveCSS("transition-duration", "2s");

  await page.setViewportSize({ width: 1440, height: 900 });
  await expect(fixture).toBeVisible();
  await expect(page).toHaveScreenshot("dark-desktop.png", { animations: "disabled" });
  await page.goto("/fixture/index.html?theme=light", { waitUntil: "networkidle" });
  await expect(fixture).toHaveAttribute("data-blab-theme", "light");
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(250, 250, 250)");
  await expect(page.getByRole("button", { name: "Primary action" })).toBeVisible();
  await expect(page).toHaveScreenshot("light-desktop.png", { animations: "disabled" });
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(page).toHaveScreenshot("light-mobile.png", { animations: "disabled" });
  expect(pageErrors).toEqual([]);
  expect(failedRequests).toEqual([]);
});
