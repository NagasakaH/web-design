FROM --platform=linux/amd64 nagasakah/web-design:base

# iptables修正（DinD対応）
RUN update-alternatives --set iptables /usr/sbin/iptables-nft && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

# code-server インストール
RUN curl -fsSL https://code-server.dev/install.sh | sh

# VS Code拡張機能プリインストール（Open VSX対応のもの）
RUN code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension bradlc.vscode-tailwindcss && \
    code-server --install-extension redhat.vscode-yaml && \
    code-server --install-extension dsznajder.es7-react-js-snippets

# NOTE: GitHub Copilot拡張機能はOpen VSXに非公開のためインストール不可。
# Copilot CLIで代替する（devcontainer feature copilot-cli:1 で導入済み）。

# 起動スクリプト配置
COPY scripts/start-code-server.sh /usr/local/bin/start-code-server
RUN chmod +x /usr/local/bin/start-code-server

# code-server設定ディレクトリの権限設定
RUN mkdir -p /home/vscode/.local/share/code-server && \
    chown -R vscode:vscode /home/vscode/.local

# DinD対応エントリポイント
ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["start-code-server"]
