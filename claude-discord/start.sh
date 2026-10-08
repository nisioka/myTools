#!/usr/bin/env bash
# Discord チャンネル常駐セッションの起動・生存確認。
#
# claude-discord.timer から定期実行される。tmux セッション claude-discord と
# その配下の discord MCP サーバが生きていれば何もせず、どちらかが欠けていれば
# 作り直す。手で叩いても安全。
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
FAILURE_CACHE="$HOME/.claude/mcp-needs-auth-cache.json"
CACHE_KEY=plugin:discord:discord
BOT_PATTERN=/plugins/cache/claude-plugins-official/discord/
BOT_WAIT_SEC=30

# systemd 配下では対話シェルの PATH が来ないので、必要なものを自前で通す。
# claude 本体 / bun (discord MCP サーバのランタイム) / node の順。
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.nvm/versions/node/v22.20.0/bin:/usr/local/bin:/usr/bin:/bin"
export TERM="${TERM:-xterm-256color}"

mkdir -p "$STATE_DIR" "$WORKSPACE"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >>"$LOG"; }

# 手動実行とタイマーが重なっても二重起動しない
exec 9>"$LOCK"
flock -n 9 || exit 0

session_alive() { tmux has-session -t "=$SESSION" 2>/dev/null; }

descendants() {
  local p
  for p in $(pgrep -P "$1"); do
    echo "$p"
    descendants "$p"
  done
}

# tmux セッションの配下で discord MCP サーバ(ボット本体)が動いているか。
# claude だけ生きていてボットが居ない状態では Discord から何も届かないので、
# セッションの有無ではなくこちらを生存の基準にする。
bot_alive() {
  local pane p
  pane=$(tmux list-panes -t "=$SESSION" -F '#{pane_pid}' 2>/dev/null | head -n1)
  [[ -n "$pane" ]] || return 1
  for p in $(descendants "$pane"); do
    if tr '\0' ' ' <"/proc/$p/cmdline" 2>/dev/null | grep -q "$BOT_PATTERN"; then
      return 0
    fi
  done
  return 1
}

# 他の claude セッション(cron 起動で PATH に bun が無いもの等)が discord の
# 接続に失敗すると、その記録がここに残り、以後15分は全セッションが接続を
# 試さずスキップする。起動がその15分に当たるとボット無しで立ち上がるので、
# 起動直前に discord の記録だけ消す。
clear_failure_cache() {
  [[ -s "$FAILURE_CACHE" ]] || return 0
  local tmp="$FAILURE_CACHE.$$.tmp"
  if jq --arg k "$CACHE_KEY" 'del(.[$k])' "$FAILURE_CACHE" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$FAILURE_CACHE"
  else
    rm -f "$tmp"
    log "WARN: $FAILURE_CACHE を更新できなかった(そのまま起動を試みる)"
  fi
}

if session_alive; then
  if bot_alive; then
    exit 0
  fi
  log "セッションはあるが discord MCP サーバが居ないので作り直す"
  tmux kill-session -t "=$SESSION"
else
  log "セッションが無いので起動する"
fi

if [[ ! -s "$TOKEN_FILE" ]]; then
  log "ERROR: $TOKEN_FILE がない/空なので起動を見送る"
  exit 1
fi

clear_failure_cache
if ! tmux new-session -d -s "$SESSION" -c "$WORKSPACE" "claude --channels $CHANNEL"; then
  log "ERROR: tmux new-session に失敗"
  exit 1
fi

# ボットが立ち上がるまで待つ(通常は数秒)
for _ in $(seq "$BOT_WAIT_SEC"); do
  sleep 1
  if ! session_alive; then
    log "ERROR: 起動直後に終了した。手動で 'cd $WORKSPACE && claude --channels $CHANNEL' を実行して原因を確認のこと"
    exit 1
  fi
  if bot_alive; then
    log "起動成功"
    exit 0
  fi
done

log "ERROR: claude は起動したが ${BOT_WAIT_SEC}秒待っても discord MCP サーバが現れない。'tmux attach -t $SESSION' して /mcp で状態を確認のこと"
exit 1
