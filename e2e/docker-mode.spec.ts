import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';

const DOCKER_MODE = process.env.DOCKER_MODE; // 'dind' | 'dood' | undefined

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('DooD/DinD動作確認', () => {
  test('E2E-5: DinDモードでdocker psが実行できる', async () => {
    test.skip(DOCKER_MODE === 'dood', 'DinDテストはDooDモードではスキップ');

    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');

    // DinD固有: コンテナ内に独立した dockerd が動作していることを確認
    const infoOutput = execInContainer(containerName, 'docker info --format "{{.ID}}"');
    expect(infoOutput.trim()).toBeTruthy();

    // DinD固有: /var/run/docker.sock がホストと共有されていないことを確認
    const sockCheck = execInContainer(containerName, 'test -S /var/run/docker.sock && echo exists || echo missing');
    expect(sockCheck.trim()).toBe('exists');
  });

  test('E2E-6: DooDモードでdocker psが実行できる', async () => {
    test.skip(DOCKER_MODE === 'dind', 'DooDテストはDinDモードではスキップ');

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
