import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('拡張機能・ツール確認', () => {
  test('E2E-3: 必要な拡張機能がインストールされている', async () => {
    const output = execInContainer(containerName, 'code-server --list-extensions');

    const requiredExtensions = [
      'dbaeumer.vscode-eslint',
      'esbenp.prettier-vscode',
      'bradlc.vscode-tailwindcss',
      'redhat.vscode-yaml',
      'dsznajder.es7-react-js-snippets',
    ];

    for (const ext of requiredExtensions) {
      expect(output.toLowerCase()).toContain(ext.toLowerCase());
    }
  });

  test('E2E-4: 開発ツールが利用可能', async () => {
    const commands = [
      'node --version',
      'npm --version',
      'git --version',
      'gh --version',
      'prettier --version',
      'yq --version',
    ];

    for (const cmd of commands) {
      const output = execInContainer(containerName, cmd);
      expect(output.trim()).not.toBe('');
    }
  });

  test('E2E-7: Copilot CLIが利用可能', async () => {
    const output = execInContainer(containerName, 'copilot --version');
    expect(output.trim()).not.toBe('');
  });
});
