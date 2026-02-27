import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('DooD/DinD動作確認', () => {
  test('E2E-5: DinDモードでdocker psが実行できる', async () => {
    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');
  });

  test('E2E-6: DooDモードでdocker psが実行できる', async () => {
    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');
  });
});
