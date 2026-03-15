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
