import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';
import { randomUUID } from 'crypto';

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('HMR反映確認', () => {
  test('E2E-8: ファイル編集がブラウザに自動反映される', async ({ page }) => {
    await page.goto('http://localhost:5173');

    const marker = `HMR-TEST-${randomUUID().slice(0, 8)}`;
    execInContainer(
      containerName,
      `bash -c "sed -i 's/Vite + React/${marker}/' /workspaces/web-design/src/App.tsx"`,
    );

    await expect(page.locator('body')).toContainText(marker, {
      timeout: 10_000,
    });

    // Restore original
    execInContainer(
      containerName,
      `bash -c "sed -i 's/${marker}/Vite + React/' /workspaces/web-design/src/App.tsx"`,
    );
  });
});
