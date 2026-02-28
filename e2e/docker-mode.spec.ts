import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';

let containerName: string;
let detectedMode: 'dind' | 'dood' | undefined;

test.beforeAll(() => {
  containerName = getContainerName();

  // Auto-detect Docker mode from container if DOCKER_MODE env is not set
  const envMode = process.env.DOCKER_MODE;
  if (envMode === 'dind' || envMode === 'dood') {
    detectedMode = envMode;
  } else {
    // Check if docker.sock is bind-mounted (DooD) or if dockerd runs inside (DinD)
    const mountCheck = execInContainer(containerName, 'mount | grep docker.sock || true').trim();
    detectedMode = mountCheck.includes('docker.sock') ? 'dood' : 'dind';
  }
});

test.describe('DooD/DinD動作確認', () => {
  test('E2E-5: DinDモードでdocker psが実行できる', async () => {
    test.skip(detectedMode === 'dood', 'DinDテストはDooDモードではスキップ');

    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');

    // DinD固有: コンテナ内に独立した dockerd が動作していることを確認
    const infoOutput = execInContainer(containerName, 'docker info --format "{{.ID}}"');
    expect(infoOutput.trim()).toBeTruthy();

    // DinD固有: /var/run/docker.sock がホストと共有されていないことを確認
    const sockCheck = execInContainer(
      containerName,
      'test -S /var/run/docker.sock && echo exists || echo missing',
    );
    expect(sockCheck.trim()).toBe('exists');
  });

  test('E2E-6: DooDモードでdocker psが実行できる', async () => {
    test.skip(detectedMode === 'dind', 'DooDテストはDinDモードではスキップ');

    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');

    // DooD固有: ホストのdocker.sockがマウントされていることを確認
    const mountCheck = execInContainer(containerName, 'mount | grep docker.sock || true');
    expect(mountCheck).toContain('docker.sock');

    // DooD固有: ホストと同じDockerデーモンを共有していることを確認
    const containerSelf = execInContainer(containerName, 'hostname').trim();
    const dockerPsOutput = execInContainer(containerName, 'docker ps --format "{{.Names}}"');
    expect(dockerPsOutput).toContain(containerSelf);
  });
});
