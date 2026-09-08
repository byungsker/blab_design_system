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
  await page.evaluate(() => document.fonts.ready);
  await expect.poll(() => page.evaluate(() => document.fonts.check('16px "Inter"'))).toBe(true);
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(18, 18, 18)");
  await expect(page.getByRole("button", { name: "Primary action" })).toBeVisible();
  const stateGallery = page.getByRole("heading", { name: "Component states" });
  await expect(stateGallery).toBeVisible();
  const focusedButton = page.getByRole("button", { name: "Focused button" });
  await expect(focusedButton).toBeFocused();
  const darkFocusShadow = await focusedButton.evaluate((element) => getComputedStyle(element).boxShadow);
  expect(darkFocusShadow).toContain("rgb(18, 18, 18)");
  await expect(page.getByRole("button", { name: "Disabled button" })).toBeDisabled();
  await expect(page.getByRole("button", { name: "Saving" })).toBeDisabled();
  await expect(page.getByRole("button", { name: "Saving" })).toHaveAttribute("aria-busy", "true");
  await expect(page.getByLabel("Error field")).toHaveAttribute("aria-invalid", "true");
  await expect(page.getByRole("alert").filter({ hasText: "Enter a valid value" })).toBeVisible();
  const darkTokens = await fixture.evaluate((element) => {
    const styles = getComputedStyle(element);
    return {
      scaffold: styles.getPropertyValue("--blab-surface-scaffold").trim(),
      primaryAction: styles.getPropertyValue("--blab-color-primary-action").trim(),
      spacing: styles.getPropertyValue("--blab-space-xxl").trim(),
      radius: styles.getPropertyValue("--blab-radius-card").trim(),
      elevation: styles.getPropertyValue("--blab-elevation-surface").trim(),
      glassBlur: styles.getPropertyValue("--blab-glass-card-blur").trim(),
      motion: styles.getPropertyValue("--blab-motion-press").trim(),
    };
  });
  expect(darkTokens).toEqual({
    scaffold: "#121212",
    primaryAction: "#4a68d3",
    spacing: "24px",
    radius: "16px",
    elevation: "0 8px 20px rgba(0, 0, 0, 0.15)",
    glassBlur: "25px",
    motion: "150ms",
  });
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
  await page.getByRole("navigation", { name: "Keyboard accessory" }).scrollIntoViewIfNeeded();
  await accessorySurface.evaluate((element) => {
    element.scrollLeft = element.scrollWidth;
  });
  await expect(page.getByRole("button", { name: "Done" })).toBeInViewport();
  await expect(page).toHaveScreenshot("dark-mobile-accessory-end.png", { animations: "disabled" });

  const longPressCard = page.getByRole("button", { name: "Long-press card" });
  await longPressCard.focus();
  await longPressCard.press("Enter");
  await expect(page.locator('[data-blab-test-output="long-press-count"]')).toHaveText("1");

  const undoButton = page.getByRole("button", { name: "Undo" });
  await undoButton.scrollIntoViewIfNeeded();
  await undoButton.hover();
  const undoStart = await page.evaluate(() => performance.now());
  await page.mouse.down();
  await page.waitForTimeout(250);
  await expect(page.locator('[data-blab-test-output="undo-count"]')).toHaveText("0");
  await expect
    .poll(async () => Number(await page.locator('[data-blab-test-output="undo-count"]').textContent()), { timeout: 2_000 })
    .toBeGreaterThan(0);
  const firstUndoEvent = Number((await page.locator('[data-blab-test-output="undo-events"]').textContent())?.split(",")[0]);
  expect(firstUndoEvent - undoStart).toBeGreaterThanOrEqual(450);
  expect(firstUndoEvent - undoStart).toBeLessThan(800);
  await expect
    .poll(async () => Number(await page.locator('[data-blab-test-output="undo-count"]').textContent()), { timeout: 1_000 })
    .toBeGreaterThan(1);
  const undoEvents = (await page.locator('[data-blab-test-output="undo-events"]').textContent())
    ?.split(",")
    .filter(Boolean)
    .map(Number) ?? [];
  const firstRepeatEvent = undoEvents[0];
  const secondRepeatEvent = undoEvents[1];
  expect(firstRepeatEvent).toBeDefined();
  expect(secondRepeatEvent).toBeDefined();
  if (firstRepeatEvent === undefined || secondRepeatEvent === undefined) {
    throw new Error("Expected two undo repeat events");
  }
  expect(secondRepeatEvent - firstRepeatEvent).toBeGreaterThanOrEqual(60);
  expect(secondRepeatEvent - firstRepeatEvent).toBeLessThan(180);
  await page.mouse.up();
  const stoppedUndoCount = Number(await page.locator('[data-blab-test-output="undo-count"]').textContent());
  await page.waitForTimeout(250);
  await expect(page.locator('[data-blab-test-output="undo-count"]')).toHaveText(String(stoppedUndoCount));

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
  await expect.poll(() => page.evaluate(() => document.fonts.check('16px "Inter"'))).toBe(true);
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(250, 250, 250)");
  await expect(page.getByRole("button", { name: "Primary action" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Focused button" })).toBeFocused();
  const lightFocusShadow = await page.getByRole("button", { name: "Focused button" }).evaluate((element) => getComputedStyle(element).boxShadow);
  expect(lightFocusShadow).toContain("rgb(250, 250, 250)");
  await expect(page.getByRole("button", { name: "Disabled button" })).toBeDisabled();
  await expect(page.getByRole("button", { name: "Saving" })).toHaveAttribute("aria-busy", "true");
  await expect(page.getByLabel("Error field")).toHaveAttribute("aria-invalid", "true");
  const lightTokens = await page.locator('[data-blab-component="parity-fixture"]').evaluate((element) => {
    const styles = getComputedStyle(element);
    return {
      scaffold: styles.getPropertyValue("--blab-surface-scaffold").trim(),
      glassFill: styles.getPropertyValue("--blab-glass-fill").trim(),
    };
  });
  expect(lightTokens).toEqual({ scaffold: "#fafafa", glassFill: "rgba(0, 0, 0, 0.08)" });
  await expect(page).toHaveScreenshot("light-desktop.png", { animations: "disabled" });
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(page).toHaveScreenshot("light-mobile.png", { animations: "disabled" });
  expect(pageErrors).toEqual([]);
  expect(failedRequests).toEqual([]);
});
