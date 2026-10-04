#!/usr/bin/env bash
# Discord チャンネル常駐セッションの起動・生存確認。
#
# claude-discord.timer から定期実行される。tmux セッション claude-discord が
# 生きていれば何もせず、落ちていれば作り直す。手で叩いても安全。
#
#   状態を見る: tmux attach -t claude-discord   (抜けるのは Ctrl-b d)
#   止める    : systemctl --user stop claude-discord.timer
#               tmux kill-session -t claude-discord
set -uo pipefail

SESSION=claude-discord
CHANNEL=plugin:discord@claude-plugins-official
WORKSPACE="$HOME/claude-discord/workspace"
TOKEN_FILE="$HOME/.claude/channels/discord/.env"
STATE_DIR="$HOME/.local/state/claude-discord"
LOG="$STATE_DIR/supervisor.log"
LOCK="$STATE_DIR/supervisor.lock"

# systemd 配下では対話シェルの PATH が来ないので、必要なものを自前で通す。
# claude 本体 / bun (discord MCP サーバのランタイム) / node の順。
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.nvm/versions/node/v22.20.0/bin:/usr/local/bin:/usr/bin:/bin"
export TERM="${TERM:-xterm-256color}"

mkdir -p "$STATE_DIR" "$WORKSPACE"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >>"$LOG"; }

# 手動実行とタイマーが重なっても二重起動しない
exec 9>"$LOCK"
flock -n 9 || exit 0

if tmux has-session -t "=$SESSION" 2>/dev/null; then
  exit 0
fi

if [[ ! -s "$TOKEN_FILE" ]]; then
  log "ERROR: $TOKEN_FILE がない/空なので起動を見送る"
  exit 1
fi

log "セッションが無いので起動する"
if tmux new-session -d -s "$SESSION" -c "$WORKSPACE" "claude --channels $CHANNEL"; then
  # 起動直後に死ぬ(クラッシュループ)場合はログに残す
  sleep 5
  if tmux has-session -t "=$SESSION" 2>/dev/null; then
    log "起動成功"
  else
    log "ERROR: 起動直後に終了した。手動で 'cd $WORKSPACE && claude --channels $CHANNEL' を実行して原因を確認のこと"
    exit 1
  fi
else
  log "ERROR: tmux new-session に失敗"
  exit 1
fi
