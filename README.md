# Codex Shogun System

Codex向けに実装した、戦国風マルチエージェント運用基盤です。

- `shogun`: 戦略統括（delegate-only）
- `karo`: タスク分解・配布
- `metsuke`: レビューゲート
- `ashigaruN`: 並列実行ワーカー（デフォルト7）
- 既定総勢: `10`（`shogun` + `karo` + `metsuke` + `ashigaru`×7）

呼称規約（固定）:

- `上様` = 人間ユーザのみ
- `将軍殿` = `shogun`
- `家老殿` = `karo`
- `目付殿` = `metsuke`
- 指揮系統: `ユーザ(上様) -> 将軍 -> 家老 -> 足軽/目付`

## Features

- tmuxベースの2セッション運用（`shogun` / `multiagent`）
- 共有タスク・メッセージ基盤（SQLite）
- 自動稼働エージェント（`bin/shogun-agent`）:
  - `karo`: タスク分配と完了上申（可能な限り分解して並列配賦）
  - `ashigaru*`: 実行とレビュー送致
  - `metsuke`: 検分（review -> done）
- 家老の分解規則:
  - 既定は `auto`（Codexによる自律分解を試行）
  - 自律分解失敗時は `parallel:` / `subtasks:` / `tasks:` と `command:` 行分割へフォールバック
  - 判定不能時は単一子任務で配賦
- 将軍画面への早馬ストリーム表示（将軍調ログ）
- 演出モード（`drama`）: 役回り自動付与、軍律（越権=再任務）、戦国調の檄と戦況報告
- 自然言語対話モード（`dialogue-mode=auto`）: 全エージェント送信文を自然文へ自動整形（LLM優先、失敗時は規則変換）
- 侍口調レベル（`samurai-tone=strong`）: 自然文を戦国調へ強く寄せる
- 会話駆動の進行（既定ON）: 足軽は「着手上申→家老応答→実働→完了上申」の往復で進める
- 自動Skill蓄積（既定ON）:
  - 完了タスクの反復コマンドを観測
  - 既存提案/既存Skillとの重複を自動判定
  - 価値ゲート（反復件数・一貫性・多様性）で提案価値を採点
  - 公式情報（一次情報URL）とLLM評価で提案品質を補強
  - Skill提案を自動起票（`skillsmith -> shogun`）
  - 承認で `skills/<slug>/SKILL.md` を生成し、ポータブル資産化
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
bin/shogunctl seed-team --ashigaru 7 --reset
bin/shogun-launch --ashigaru 7 --comm-mode teams
```

`bin/shogun-launch` は既定で:

- `ashigaru=7`
- `autopilot=ON`（家老/目付/足軽が自動稼働）
- `leader-watch=ON`（将軍paneで受信早馬を表示）
- `feed=ON`（将軍ウィンドウで全隊の task/message を常時表示）
  - `feed-truncate=0`（要約せず全文表示）
- `drama=ON`（戦国演出ログ・役回り自動付与）
- `karo-decompose-mode=auto`（人間寄りの自律分解を優先）
- `ashigaru-exec-mode=auto`（必要時に自律実行へ移行）
- `dialogue-mode=auto`（定型文を自然言語へ自動変換）
- `samurai-tone=strong`（侍口調を強めに適用）
- `ashigaru-ack-wait-sec=8`（足軽が家老の裁可を待つ秒数）
- `ashigaru-progress-interval-sec=10`（裁可待ち/実働中の中間報告間隔）
- `skills=ON`（反復作業からSkill提案を自動起票）
  - `skill-interval-sec=30`
  - `skill-min-count=3`
  - 提案起票時に重複/価値/調査ゲートを実行
- 直前の task/message/event をクリアしてから起動

Attach:

```bash
tmux attach -t shogun
tmux attach -t multiagent
```

### Parallel Decomposition (Karo)

親任務の `description` に以下を含めると、家老が子任務へ分解して複数足軽へ配賦します。

既定の `karo-decompose-mode=auto` では、まず Codex による分解を試み、失敗した場合のみ以下の明示ルールで分解します。

```text
parallel:
- build docs :: pnpm run docs:build
- test unit :: pnpm run test:unit
- command: pnpm run lint
```

または:

```text
command:
pnpm run lint
pnpm run test:unit
pnpm run test:e2e
```

注: `&&`, `||`, `|`, `;` などの制御記号を含む複文は依存関係不明として自動分割しません。

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
bin/shogun-feed --once --delta-only --cursor-file state/feed.cursor.json --truncate 0
bin/shogun-skillflow scan --once --json
bin/shogun-skillflow list
bin/shogun-skillflow show --id 1
bin/shogun-skillflow approve --id 1
bin/shogun-skillflow reject --id 2
bin/shogun-skillflow scan --no-research-llm --no-research-docs --json
bin/shogun-remote status
bin/shogun-remote ask "本家との差分を比較し、改善案を3案示せ"
bin/shogun-remote run "pnpm test"                  # strict delegate (default)
bin/shogun-remote run --direct "bin/shogunctl status"  # direct run (bypass strict)
bin/shogun-watch 5
bin/shogun-watchdog --task-timeout-min 10 --member-timeout-min 10 --dry-run
bin/shogun-autoflow --json
bin/shogun-agent --name karo --role karo --mode teams --once
```

`bin/shogun-feed --delta-only --cursor-file ...` は前回表示以降の新着イベント/メッセージのみを出力する。

`bin/shogun-remote` ingress policy:

- 思考系依頼（比較・設計・検討・企画）: `bin/shogun-remote ask "..."`
- 実行系依頼（コマンド遂行）: `bin/shogun-remote run "..."`

`bin/shogun-remote run` is strict by default (`SHOGUN_REMOTE_STRICT=1`):

- creates a task
- sends a delegated message to `karo`
- does not execute command directly unless `--direct` is used
- by default waits for task completion and prints final shogun report to 上様

`bin/shogun-remote ask/run` completion tracking options:

- `--await / --no-await`: 完了待機の有効/無効（既定は有効）
- `--await-timeout-sec N`: 完了待機タイムアウト秒
- `--await-poll-sec SEC`: ステータスポーリング間隔
- `--stream MODE`: 待機中の逐次表示対象（`all|task|shogun|off`、既定 `all`）
- `--db PATH`: 追跡に使うDBパス（既定 `state/shogun.db`）
- 完了待機中は `--stream` 設定に応じて全軍議ログ/該当任務ログ/将軍宛上申を逐次表示

Root task ingress guard:

- `parent_id` のない新規タスク（root task）は `actor=shogun` のみ作成可能
- 例外が必要な検証時のみ `SHOGUN_ALLOW_NON_SHOGUN_ROOT_TASKS=1` で一時的に緩和
- `bin/shogun-remote` の `sender` 既定は `SHOGUN_NAME`（未設定時は `shogun`）

`bin/shogun-launch` options:

- `--no-autopilot`: 自動稼働を無効化（手動操作のみ）
- `--agent-interval SEC`: 自動稼働ループの周期
- `--drama / --no-drama`: 戦国演出モードON/OFF（既定ON）
- `--karo-decompose-mode MODE`: 家老の分解モード（`auto|llm|rule`）
- `--ashigaru-exec-mode MODE`: 足軽の実行モード（`auto|codex|shell`）
- `--dialogue-mode MODE`: 送信文スタイル（`auto|llm|template`）
- `--samurai-tone LEVEL`: 侍口調の強さ（`strong|light`）
- `--ashigaru-ack-wait-sec SEC`: 足軽が家老の応答を待ってから実働へ移る待機時間
- `--ashigaru-progress-interval-sec SEC`: 足軽の中間報告間隔
- `--skills / --no-skills`: 自動Skill提案デーモンON/OFF（既定ON）
- `--skill-interval-sec SEC`: Skill提案スキャン間隔
- `--skill-min-count N`: Skill提案の最小反復回数
- `--skill-sender NAME`: Skill提案メッセージ送信者名（既定 `skillsmith`）
- `--leader-watch / --no-leader-watch`: 将軍paneの受信早馬表示ON/OFF
- `--feed / --no-feed`: 将軍ウィンドウの全隊フィード表示ON/OFF
- `--feed-tail-events N --feed-tail-messages N --feed-interval SEC`: フィード表示調整（`N=0` は全件）
- `--feed-truncate N`: フィード文字数制限（`0` は要約なし全文）
- `--watch`: 旧watchログを `/tmp/shogun-watch-*.log` へ保存

`bin/shogun-agent` options:

- `--output-max-chars N`: 実行ログをメッセージに含める最大文字数（`0` は無制限）
- `--drama / --no-drama`: 役回り・檄・軍律メッセージの演出ON/OFF（`SHOGUN_DRAMA_MODE` でも指定可）
- `--karo-decompose-mode auto|llm|rule`: 家老の分解戦略（既定 `auto`）
- `--ashigaru-exec-mode auto|codex|shell`: 足軽の実行戦略（既定 `auto`）
- `--dialogue-mode auto|llm|template`: エージェント間メッセージの自然言語化戦略（既定 `auto`）
- `--samurai-tone strong|light`: 自然言語メッセージの戦国口調レベル（既定 `strong`）
- `--ashigaru-ack-wait-sec`: 裁可待ちタイムアウト（既定 `8` 秒）
- `--ashigaru-progress-interval-sec`: 中間報告間隔（既定 `10` 秒）
- `--karo-codex-bin`, `--ashigaru-codex-bin`: 自律実行に使うCodex実行ファイル（既定 `codex`）
- `--dialogue-codex-bin`: 対話文リライトに使うCodex実行ファイル（既定 `codex`）

`bin/shogun-skillflow scan` options (主要):

- `--min-count N`: 提案対象にする最小反復回数
- `--gate-min-score S`: 価値ゲート合格点（既定 `4.5`）
- `--research-docs / --no-research-docs`: 公式情報URL取得ON/OFF
- `--research-llm / --no-research-llm`: LLM評価ON/OFF
- `--require-llm-propose`: LLM推奨が `propose` のときのみ提案作成
- `--publish-dir PATH`: 既存Skill重複判定に使うSkill保存先

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
