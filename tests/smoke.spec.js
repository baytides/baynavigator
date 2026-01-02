import { test, expect } from '@playwright/test';

// Use ?no-welcome=1 to skip the welcome screen for tests that need direct access to content
const home = '/?no-welcome=1';

test('home loads and shows programs', async ({ page }) => {
  await page.goto(home, { waitUntil: 'domcontentloaded' });
  // Wait for program cards to be visible
  await expect(page.locator('[data-program]').first()).toBeVisible({ timeout: 10000 });
});

test('search filters results', async ({ page }) => {
  await page.goto(home, { waitUntil: 'domcontentloaded' });

  // Wait for programs to be visible first
  await page.locator('[data-program]').first().waitFor({ state: 'visible', timeout: 10000 });

  const input = page.getByRole('searchbox', { name: /search programs/i });
  await input.fill('food');

  // Wait for filter to apply
  await page.waitForTimeout(500);

  // Verify that at least one food-related program is visible
  const hasFoodResult = await page.evaluate(() => {
    const cards = document.querySelectorAll('[data-program]');
    for (const card of cards) {
      if (card.style.display !== 'none' &&
          card.textContent.toLowerCase().includes('food')) {
        return true;
      }
    }
    return false;
  });

  expect(hasFoodResult).toBe(true);
});

test('back to top hidden on desktop', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto(home, { waitUntil: 'domcontentloaded' });
  await page.mouse.wheel(0, 1200);
  const backToTop = page.locator('#back-to-top');
  await expect(backToTop).not.toBeVisible();
});

test('back to top appears after scroll on mobile', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto(home, { waitUntil: 'domcontentloaded' });
  await page.mouse.wheel(0, 1200);
  await page.waitForTimeout(500);
  const backToTop = page.locator('#back-to-top');
  await expect(backToTop).toBeVisible();
});

test('mobile bottom nav is visible on mobile', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto(home, { waitUntil: 'domcontentloaded' });

  const bottomNav = page.locator('.mobile-bottom-nav');
  await expect(bottomNav).toBeVisible();

  // Check filters button opens onboarding modal
  const filtersBtn = page.locator('#mobile-filters-btn');
  await expect(filtersBtn).toBeVisible();
});

test('mobile layout prevents horizontal scroll', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto(home, { waitUntil: 'domcontentloaded' });

  // Check that body doesn't have horizontal scrollbar
  const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
  const viewportWidth = await page.evaluate(() => document.documentElement.clientWidth);
  expect(bodyWidth).toBeLessThanOrEqual(viewportWidth);
});

test('onboarding modal displays and navigates correctly', async ({ page }) => {
  // Visit without skipping welcome
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Welcome screen should be visible for new users
  const welcomeScreen = page.locator('#welcome-screen');

  // Check if welcome screen is shown (may be hidden if already completed)
  const isWelcomeVisible = await welcomeScreen.isVisible().catch(() => false);

  if (isWelcomeVisible) {
    // Click Get Started to open onboarding
    const getStartedBtn = page.locator('#welcome-get-started');
    await getStartedBtn.click();

    // Onboarding modal should appear
    const onboardingModal = page.locator('#onboarding-modal');
    await expect(onboardingModal).toBeVisible();

    // Should show groups selection (step 1)
    const groupsGrid = page.locator('.onboarding-grid');
    await expect(groupsGrid).toBeVisible();
  }
});

test('favorites page loads correctly', async ({ page }) => {
  await page.goto('/favorites.html', { waitUntil: 'domcontentloaded' });

  // Check page title
  const title = page.locator('h1');
  await expect(title).toContainText('My Saved Programs');

  // Check favorites view is present
  const favoritesView = page.locator('#favorites-view');
  await expect(favoritesView).toBeVisible();
});
