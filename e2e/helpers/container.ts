import { execSync } from 'child_process';

/**
 * dev-container.sh で起動したコンテナの名前を動的に取得する。
 * label "managed-by=dev-container-sh" でフィルタリングする。
 */
export function getContainerName(): string {
  const output = execSync(
    "docker ps --filter label=managed-by=dev-container-sh --format '{{.Names}}'",
  )
    .toString()
    .trim();

  const containers = output.split('\n').filter(Boolean);
  if (containers.length === 0) {
    throw new Error('No running container found with label managed-by=dev-container-sh');
  }
  const webDesign = containers.find((c) => c.startsWith('web-design-'));
  return webDesign || containers[0];
}

/**
 * コンテナ内でコマンドを実行するヘルパー
 */
export function execInContainer(containerName: string, cmd: string): string {
  return execSync(`docker exec ${containerName} ${cmd}`).toString();
}
