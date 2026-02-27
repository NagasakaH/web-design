import { test, expect } from '@playwright/test';

test.describe('code-server アクセス確認', () => {
  test('E2E-1: code-serverにブラウザからアクセスできる', async ({ page }) => {
    await page.goto('http://localhost:8080');
    await expect(page).toHaveTitle(/code-server|Visual Studio Code/i);
  });
});
