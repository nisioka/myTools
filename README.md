# myTools

個人用ツール集。

## ws - Workspace Manager

tmuxベースのワークスペース管理ツール。IDEのターミナルごとにtmuxセッションを作成し、別モニターでダッシュボード（全セッションのタイル表示）をミラーできる。

### 導入方法

```bash
# リポジトリをクローン
git clone https://github.com/nisioka/myTools.git

# PATHの通ったディレクトリにシンボリックリンクを作成
ln -s "$(pwd)/myTools/shell/ws" ~/.local/bin/ws

# または直接PATHに追加
export PATH="$PATH:/path/to/myTools/shell"
```

実行権限が必要です:

```bash
chmod +x shell/ws
```

### 依存

- bash 4+ (連想配列を使用)
- tmux

### コマンド

```
ws add [-g group] [name]            セッションを作成してattach（名前省略=カレントディレクトリ名）
ws rm [name]                        セッションを終了
ws list [-g group] [-G group]       一覧表示
ws dash [-g group] [-G group]       ミラーダッシュボードを開く
ws help                             ヘルプ
```

### グループ機能

`-g` オプションでセッションをグループに分類し、表示時にフィルタリングできる。

```bash
# グループ付きでセッション作成
cd ~/projects/api && ws add -g backend
cd ~/projects/web && ws add -g frontend

# グループで絞り込み / 除外
ws list -g backend          # backendグループのみ表示
ws list -G frontend         # frontendグループを除外
ws dash -g backend          # backendグループのみダッシュボード表示

# 既存セッションにグループを後付け
ws add -g backend api
```

グループ情報は `~/.config/ws/groups` に保存される。

### 使い方の例

```bash
# 1. 各IDEのターミナルでセッションを作成
cd ~/projects/api && ws add
cd ~/projects/web && ws add

# 2. 別モニターでダッシュボードを開く
ws dash    # 全セッションがタイル表示でミラーされる

# 3. 不要になったセッションを終了
ws rm api
```

### ダッシュボード操作

| キー | 操作 |
|------|------|
| `Ctrl+B` → 矢印 | ペイン間移動（入力も可能） |
| `Ctrl+B` → `D` | ダッシュボードから抜ける |

## claude-discord - Claude Code の Discord 常駐セッション

Claude Code を Discord チャンネル付きで tmux セッション `claude-discord` に常駐させ、落ちていたら systemd user timer が起こし直す。メインPC（WSL2）で動かしている。

- `claude-discord/start.sh` — セッションの起動・生存確認（手で叩いても安全）
- `claude-discord/claude-discord.service` / `.timer` — 起動時と1日1回 `start.sh` を呼ぶ

### 導入方法

実体はこのリポジトリに置き、稼働場所からシンボリックリンクで参照する。
リンク先に同名のファイルが既にあると `ln -s` が失敗して古いものが残るので、先に退避しておく。

```bash
mkdir -p ~/claude-discord ~/.config/systemd/user
ln -s "$(pwd)/claude-discord/start.sh" ~/claude-discord/start.sh
ln -s "$(pwd)/claude-discord/claude-discord.service" ~/.config/systemd/user/
ln -s "$(pwd)/claude-discord/claude-discord.timer" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now claude-discord.timer
```

Discord のトークンは `~/.claude/channels/discord/.env`（リポジトリ外）。作業ディレクトリは `~/claude-discord/workspace`、ログは `~/.local/state/claude-discord/supervisor.log`。

### 依存

- tmux / claude / bun（discord MCP サーバのランタイム）

## jev - TypeSafe AI (Jev) お試し環境

TypeSafe AI の System One モデル Jev をローカルで叩くサンドボックス。詳細は [jev/README.md](jev/README.md)。

```bash
cd jev && pnpm install && cp .env.example .env   # .env に TYPESAFE_API_KEY を書く
pnpm demo
```
