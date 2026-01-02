const { test, expect } = require('@playwright/test');

// Note: Utility bar is now hidden on mobile (< 768px) - controls are in bottom nav and sidebar

test.describe('Recent Changes - Desktop Sidebar and Dark Mode', () => {
  test('desktop sidebar appears on index page (1024px+ viewport)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    // Check logo is present in sidebar
    const logo = page.locator('.sidebar-logo');
    await expect(logo).toBeVisible();
    await expect(logo).toHaveAttribute('aria-label', /Bay Navigator Home/i);

    // Check navigation is present
    const nav = page.locator('#desktop-sidebar nav');
    await expect(nav).toBeVisible();
  });

  test('desktop sidebar appears on privacy page', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/privacy.html');

    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    // Check logo is clickable and goes to home
    const logo = page.locator('.sidebar-logo');
    await expect(logo).toBeVisible();
    await expect(logo).toHaveAttribute('href', '/');
  });

  test('desktop sidebar appears only once (no duplicates)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const sidebars = page.locator('#desktop-sidebar');
    await expect(sidebars).toHaveCount(1);
  });

  test('sidebar theme toggle cycles through modes (desktop)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

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

    // Click to cycle back to Auto/System
    await themeToggle.click();
    await expect(themeLabel).toHaveText('System');
  });

  test('dark mode applies correct CSS variables (desktop)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const body = page.locator('body');
    const themeToggle = page.locator('#sidebar-theme-toggle');

    // Click twice: auto -> light -> dark
    await themeToggle.click();
    await themeToggle.click();
    await expect(body).toHaveAttribute('data-theme', 'dark');

    // Check that dark mode CSS variables are applied
    const bgColor = await body.evaluate((el) => {
      return getComputedStyle(el).getPropertyValue('--bg-main').trim();
    });
    expect(bgColor).toBe('#0d1117'); // Dark mode background
  });

  test('light mode applies correct CSS variables (desktop)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const body = page.locator('body');
    const themeToggle = page.locator('#sidebar-theme-toggle');

    // Click once: auto -> light
    await themeToggle.click();
    await expect(body).toHaveAttribute('data-theme', 'light');

    // Check that light mode CSS variables are applied
    const bgColor = await body.evaluate((el) => {
      return getComputedStyle(el).getPropertyValue('--bg-main').trim();
    });
    // Browser may return 'white' or '#ffffff' depending on how it normalizes
    expect(['white', '#ffffff']).toContain(bgColor); // Light mode background
  });

  test('privacy policy text is visible in dark mode (desktop via sidebar)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/privacy.html');

    // Use sidebar theme toggle
    const themeToggle = page.locator('#sidebar-theme-toggle');

    // Click twice to get to dark mode (auto -> light -> dark)
    await themeToggle.click();
    await themeToggle.click();

    // Check content wrapper is visible
    const contentWrapper = page.locator('.content-wrapper');
    await expect(contentWrapper).toBeVisible();

    // Check that h1 exists and is visible
    const h1 = page.locator('.content-wrapper h1').first();
    await expect(h1).toBeVisible();
  });

  test('sidebar navigation has correct structure', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    // Check sidebar nav items exist
    const navItems = page.locator('.sidebar-nav-item');
    const navCount = await navItems.count();
    expect(navCount).toBeGreaterThan(0);

    // Check first nav item is properly labeled
    const firstNavItem = navItems.first();
    const label = await firstNavItem.locator('.sidebar-nav-label').textContent();
    expect(label).toBeTruthy();
  });

  test('responsive design on mobile (375x667)', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // Desktop sidebar should be hidden on mobile
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).not.toBeInViewport();

    // Utility bar should be hidden on mobile (new design)
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();

    // Mobile bottom nav should be visible
    const bottomNav = page.locator('.mobile-bottom-nav');
    await expect(bottomNav).toBeVisible();
  });

  test('responsive design on tablet (768x1024)', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');

    // Desktop sidebar should be hidden on tablet (under 1024px)
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).not.toBeInViewport();

    // Utility bar should be hidden on tablet (new design)
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();
  });

  test('responsive design on desktop (1920x1080)', async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto('/');

    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    const logo = page.locator('.sidebar-logo');
    await expect(logo).toBeVisible();

    const nav = page.locator('#desktop-sidebar nav');
    await expect(nav).toBeVisible();

    // Utility bar should be hidden on desktop
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();
  });
});
