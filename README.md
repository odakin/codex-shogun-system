# Codex Shogun System

Codex向けに実装した、戦国風マルチエージェント運用基盤です。

- `shogun`: 戦略統括（delegate-only）
- `karo`: タスク分解・配布
- `metsuke`: レビューゲート
- `ashigaruN`: 並列実行ワーカー（デフォルト10）

## Features

- tmuxベースの2セッション運用（`shogun` / `multiagent`）
- 共有タスク・メッセージ基盤（SQLite）
- 自動稼働エージェント（`bin/shogun-agent`）:
  - `karo`: タスク分配と完了上申
  - `ashigaru*`: 実行とレビュー送致
  - `metsuke`: 検分（review -> done）
- 将軍画面への早馬ストリーム表示（将軍調ログ）
- 通信方式の切替:
  - `teams`（共有メッセージング）
  - `sendkeys`（Gen1）
  - `ntfy`（Gen2）
  - `mailbox` / `hybrid`（Gen3: mailbox + nudge）
- Agent Teams風API互換:
  - `TeamCreate`, `SendMessage`, `TaskCreate`, `TaskUpdate`, `TaskList`, `Task`
- watchdog（滞留検知）/ autoflow（レビュー導線自動化）
- delegateガード（将軍の自己実行と足軽直指示を禁止）

## Requirements

- `bash`
- `python3` (3.9+)
- `tmux`
- (optional) `gh` for GitHub operations

## Quick Start

```bash
bin/shogunctl init
bin/shogunctl seed-team --ashigaru 10 --reset
bin/shogun-launch --ashigaru 10 --comm-mode teams
```

`bin/shogun-launch` は既定で:

- `ashigaru=10`
- `autopilot=ON`（家老/目付/足軽が自動稼働）
- `leader-watch=ON`（将軍paneで受信早馬を表示）
- `feed=ON`（将軍ウィンドウで全隊の task/message を常時表示）
- 直前の task/message/event をクリアしてから起動

Attach:

```bash
tmux attach -t shogun
tmux attach -t multiagent
```

## Communication Modes

### teams

```bash
bin/shogun-comm --mode teams send --from shogun --to karo --content "new task"
bin/shogun-comm --mode teams read --name karo --unread-only --mark-read
```

### sendkeys (Gen1)

```bash
bin/shogun-launch --comm-mode sendkeys
bin/shogun-comm --mode sendkeys send --from karo --to ashigaru1 --content "work now"
```

### ntfy (Gen2)

```bash
bin/shogun-comm --mode ntfy send --from shogun --to karo --content "status?"
bin/shogun-comm --mode ntfy read --name karo
```

### mailbox / hybrid (Gen3)

```bash
bin/shogun-launch --comm-mode hybrid --watch
bin/inbox_write.sh --from karo --to ashigaru1 --content "Task #12"
bin/inbox_read.sh --name ashigaru1 --mark-read
bin/nudge_send.sh --from karo --to ashigaru1
```

## Agent Teams-style API

```bash
bin/shogun-api call TeamCreate team_name=shogun-team
bin/shogun-api call Task subagent_type=general-purpose team_name=shogun-team name=karo mode=delegate prompt="Read instructions/karo.md"
bin/shogun-api call TaskCreate actor=shogun owner=karo subject="WBS更新" description="分解して割り当て"
bin/shogun-api call TaskUpdate taskId=1 actor=shogun owner=karo
bin/shogun-api call SendMessage type=message sender=shogun recipient=karo content="TaskListを確認せよ"
bin/shogun-api call TaskList owner=karo status=todo
```

## Ops

```bash
bin/shogunctl status
bin/shogunctl status --recent-events 20 --recent-messages 40
bin/shogun-remote status
bin/shogun-remote run "pnpm test"                  # strict delegate (default)
bin/shogun-remote run --direct "bin/shogunctl status"  # direct run (bypass strict)
bin/shogun-watch 5
bin/shogun-watchdog --task-timeout-min 10 --member-timeout-min 10 --dry-run
bin/shogun-autoflow --json
bin/shogun-agent --name karo --role karo --mode teams --once
```

`bin/shogun-remote run` is strict by default (`SHOGUN_REMOTE_STRICT=1`):

- creates a task
- sends a delegated message to `karo`
- does not execute command directly unless `--direct` is used

`bin/shogun-launch` options:

- `--no-autopilot`: 自動稼働を無効化（手動操作のみ）
- `--agent-interval SEC`: 自動稼働ループの周期
- `--leader-watch / --no-leader-watch`: 将軍paneの受信早馬表示ON/OFF
- `--feed / --no-feed`: 将軍ウィンドウの全隊フィード表示ON/OFF
- `--feed-tail-events N --feed-tail-messages N --feed-interval SEC`: フィード表示調整
- `--watch`: 旧watchログを `/tmp/shogun-watch-*.log` へ保存

Reset runtime data:

```bash
bin/shogunctl reset
```

## Policy

`shogun` is delegate-only:

- cannot execute work commands directly
- cannot assign tasks/messages directly to `ashigaru*`
- must delegate via `karo`

## Project Layout

- `bin/`: control plane, comm layer, launchers, compatibility wrappers
- `instructions/`: role definitions
- `state/`: runtime state (DB/mailboxes/spool; mostly ignored from git)
- `CLAUDE.md`: protocol and role constraints
