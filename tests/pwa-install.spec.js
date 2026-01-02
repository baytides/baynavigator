import { test, expect } from '@playwright/test';

const home = '/';

// Helper to fire a synthetic beforeinstallprompt event
async function triggerBeforeInstallPrompt(page, outcome = 'accepted') {
  await page.evaluate(async (desiredOutcome) => {
    const e = new Event('beforeinstallprompt');
    // Provide the properties our app code expects
    e.prompt = () => {};
    e.userChoice = Promise.resolve({ outcome: desiredOutcome });
    // Dispatch the event
    window.dispatchEvent(e);
  }, outcome);
}

// Note: Utility bar is now hidden on mobile (< 768px) - PWA install is in sidebar on desktop

test.describe('PWA Install Button (Desktop Sidebar)', () => {
  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
  });

  test('sidebar install button appears on beforeinstallprompt', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    const installItem = page.locator('#sidebar-install-item');
    const installBtn = page.locator('#sidebar-install');

    // Install button should be hidden by default
    await expect(installItem).toHaveCSS('display', 'none');

    // Fire the synthetic beforeinstallprompt event
    await triggerBeforeInstallPrompt(page, 'accepted');

    // Install button should now be visible in sidebar
    await expect(installItem).not.toHaveCSS('display', 'none');
    await expect(installBtn).toBeVisible();
  });

  test('sidebar install button triggers install and hides after', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    const installItem = page.locator('#sidebar-install-item');
    const installBtn = page.locator('#sidebar-install');

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');
    await expect(installItem).not.toHaveCSS('display', 'none');
    await expect(installBtn).toBeVisible();

    // Click the button to trigger install
    await installBtn.click();

    // After install prompt flow, button should be hidden again
    await expect(installItem).toHaveCSS('display', 'none');

    // And the global deferredPrompt should be cleared
    const deferred = await page.evaluate(() => window.deferredPrompt);
    expect(deferred).toBeNull();
  });

  test('sidebar install button hides on appinstalled event', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    const installItem = page.locator('#sidebar-install-item');

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');
    await expect(installItem).not.toHaveCSS('display', 'none');

    // Simulate the browser firing the appinstalled event
    await page.evaluate(() => {
      window.dispatchEvent(new Event('appinstalled'));
    });

    // Install button should be hidden
    await expect(installItem).toHaveCSS('display', 'none');

    // And the global deferredPrompt should be cleared
    const deferred = await page.evaluate(() => window.deferredPrompt);
    expect(deferred).toBeNull();
  });

  test('sidebar install button has correct accessibility attributes', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');

    const installBtn = page.locator('#sidebar-install');
    await expect(installBtn).toHaveAttribute('aria-label', 'Install app');
    await expect(installBtn).toHaveAttribute('type', 'button');
  });
});

test.describe('PWA Install - Mobile Bottom Nav', () => {
  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
  });

  test('mobile bottom nav is visible on mobile', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    const bottomNav = page.locator('.mobile-bottom-nav');
    await expect(bottomNav).toBeVisible();
  });

  test('mobile bottom nav has programs, saved, guides, and filters', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    // Check for Programs link
    const programsLink = page.locator('.mobile-bottom-nav a[href="/"]');
    await expect(programsLink).toBeVisible();

    // Check for Saved link
    const savedLink = page.locator('.mobile-bottom-nav a[href="/favorites.html"]');
    await expect(savedLink).toBeVisible();

    // Check for Guides link
    const guidesLink = page.locator('.mobile-bottom-nav a[href="/eligibility/"]');
    await expect(guidesLink).toBeVisible();

    // Check for Filters button
    const filtersBtn = page.locator('#mobile-filters-btn');
    await expect(filtersBtn).toBeVisible();
  });
});
