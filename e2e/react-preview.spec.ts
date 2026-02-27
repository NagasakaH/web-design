import { test, expect } from '@playwright/test';

test.describe('Reactアプリプレビュー確認', () => {
  test('E2E-2: Reactアプリがプレビューできる', async ({ page }) => {
    await page.goto('http://localhost:5173');
    await expect(page.locator('body')).toContainText(/Vite|React/i);
  });
});
