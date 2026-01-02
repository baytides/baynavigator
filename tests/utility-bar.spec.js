const { test, expect } = require('@playwright/test');

// Note: Utility bar is now hidden on mobile (< 768px) - controls are in bottom nav and sidebar
// These tests focus on desktop behavior where utility bar is visible (768px-1023px)
// and sidebar tests for larger screens

test.describe('Utility Bar (Tablet - 768px to 1023px)', () => {
  // Utility bar is only visible in tablet range (768-1023px)
  // On mobile (<768px) it's hidden, on desktop (1024px+) sidebar is used

  test('utility bar is hidden on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/?no-step=1');

    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();
  });

  test('sidebar appears on desktop instead of utility bar', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/?no-step=1');

    // Utility bar should be hidden on desktop
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();

    // Sidebar should be visible instead
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    // Sidebar theme toggle should work
    const themeToggle = page.locator('#sidebar-theme-toggle');
    await expect(themeToggle).toBeVisible();
  });

  test('sidebar theme toggle works on desktop', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/?no-step=1');

    const body = page.locator('body');
    const themeToggle = page.locator('#sidebar-theme-toggle');
    const themeLabel = page.locator('#theme-label');

    // Initial state should be System/Auto
    await expect(themeLabel).toHaveText('System');

    // Click to cycle to Light
    await themeToggle.click();
    await expect(themeLabel).toHaveText('Light');
    await expect(body).toHaveAttribute('data-theme', 'light');

    // Click to cycle to Dark
    await themeToggle.click();
    await expect(themeLabel).toHaveText('Dark');
    await expect(body).toHaveAttribute('data-theme', 'dark');
  });

  test('theme preferences persist after page reload', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/?no-step=1');

    // Set dark theme via sidebar
    const themeToggle = page.locator('#sidebar-theme-toggle');
    // Click twice: auto -> light -> dark
    await themeToggle.click();
    await themeToggle.click();

    // Wait for localStorage to be set
    await page.waitForTimeout(100);

    // Reload page
    await page.reload();

    // Wait for page to load
    await page.waitForLoadState('domcontentloaded');

    // Check preferences were saved
    await expect(page.locator('body')).toHaveAttribute('data-theme', 'dark');
  });
});

test.describe('Utility Bar Hidden on Desktop', () => {
  test('utility bar is hidden on desktop with sidebar', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/?no-step=1');

    // Utility bar should be hidden on desktop
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();

    // Sidebar should be visible instead
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();
  });
});
