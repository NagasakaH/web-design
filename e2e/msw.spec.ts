import { test, expect } from '@playwright/test';

test.describe('MSWモック応答確認', () => {
  test('E2E-9: /api/health がMSWモックレスポンスを返す', async ({ page }) => {
    await page.goto('http://localhost:5173');
    await page.waitForTimeout(2000);

    const response = await page.evaluate(async () => {
      const res = await fetch('/api/health');
      return res.json();
    });

    expect(response).toEqual({ status: 'ok' });
  });

  test('E2E-10: MSW Service Workerが正常に登録されている', async ({ page }) => {
    await page.goto('http://localhost:5173');
    await page.waitForTimeout(2000);

    const swRegistered = await page.evaluate(async () => {
      const registrations = await navigator.serviceWorker.getRegistrations();
      return registrations.some((r) => r.active?.scriptURL.includes('mockServiceWorker.js'));
    });
    expect(swRegistered).toBe(true);
  });
});
