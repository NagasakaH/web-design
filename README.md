# web-design

Web デザイン要件定義プロジェクト環境。  
ブラウザベースの開発環境（code-server + Vite + React + TypeScript + Tailwind CSS + MSW）を提供します。

## 技術スタック

| 技術 | バージョン / 説明 |
|------|-------------------|
| code-server | ブラウザベース VS Code |
| React + TypeScript | React 19 + TypeScript 5 |
| Vite | 6（HMR 対応） |
| Tailwind CSS | 4 |
| MSW | 2（API モッキング） |
| Playwright | E2E テスト |
| Docker | DinD / DooD 対応 |

## 前提条件

- Docker Engine 20.10+
- devcontainer CLI（ビルド用）
- ポート 8080, 5173 が利用可能であること

## クイックスタート

```bash
# DinD モード（デフォルト）
./scripts/dev-container.sh up

# DooD モード
DOCKER_MODE=dood ./scripts/dev-container.sh up
```

- code-server: http://localhost:8080
- Vite dev server: http://localhost:5173

## 開発ワークフロー

1. コンテナを起動: `./scripts/dev-container.sh up`
2. ブラウザで code-server にアクセス: http://localhost:8080
3. code-server 内でターミナルを開く
4. `npm install && npm run dev` を実行
5. http://localhost:5173 で React プレビューを確認

## npm スクリプト

| コマンド | 説明 |
|----------|------|
| `npm run dev` | Vite 開発サーバー起動（HMR） |
| `npm run build` | プロダクションビルド |
| `npm run preview` | ビルド結果のプレビュー |
| `npm run lint` | ESLint によるコード検査 |
| `npm run format` | Prettier によるフォーマット |
| `npm run format:check` | フォーマットチェック（CI 用） |
| `npm run test:e2e` | Playwright E2E テスト実行 |
| `npm run test:e2e:ui` | Playwright UI モードで実行 |

## DooD/DinD モード切り替え

環境変数 `DOCKER_MODE` でモードを切り替えます。

- **DinD（Docker in Docker）**: コンテナ内部で Docker デーモンを起動します。デフォルトモード。
- **DooD（Docker outside of Docker）**: ホストの Docker ソケットを共有して使用します。

```bash
# DinD モード（デフォルト）
./scripts/dev-container.sh up

# DooD モード
DOCKER_MODE=dood ./scripts/dev-container.sh up
```

## プリビルトイメージのビルド

```bash
# ローカルビルドのみ
./scripts/build-and-push-devcontainer.sh --no-push

# ビルド + プッシュ
./scripts/build-and-push-devcontainer.sh
```

## コンテナ管理

```bash
./scripts/dev-container.sh status   # コンテナ状態確認
./scripts/dev-container.sh shell    # コンテナ内シェルに接続
./scripts/dev-container.sh logs     # ログ表示
./scripts/dev-container.sh down     # コンテナ停止・削除
```

## E2E テスト実行

```bash
npx playwright test
npx playwright show-report
```

## ⚠️ セキュリティに関する注意

> **重要**: 以下のセキュリティ上の注意事項を必ず確認してください。

- `--auth none` は **ローカル開発専用** です。公開ネットワークには絶対に公開しないでください。
- `--privileged` フラグは DinD/DooD の動作に必要ですが、**信頼できるローカル環境でのみ** 使用してください。
- リモートアクセスが必要な場合は `--auth password` に変更してください。

## GitHub Copilot CLI

- Copilot VS Code 拡張機能は code-server では利用**できません**（Open VSX の制限）。
- 代替として **Copilot CLI** が devcontainer feature 経由で利用可能です。
- 使用方法: `github-copilot-cli` コマンドを実行してください。

---

> **Note**: このプロジェクトは [dev-process](https://github.com/) リポジトリのパターンをベースにしています。
