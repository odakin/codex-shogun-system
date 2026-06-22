# Codex Shogun System

Codex向けに実装した、戦国風マルチエージェント運用基盤です。

- `shogun`: 戦略統括（delegate-only）
- `karo`: タスク分解・配布
- `metsuke`: レビューゲート
- `ashigaruN`: 並列実行ワーカー（デフォルト7）
- 既定総勢: `10`（`shogun` + `karo` + `metsuke` + `ashigaru`×7）

指揮系統: `ユーザ(上様) -> 将軍 -> 家老 -> 足軽/目付`。呼称規約（`上様`=人間ユーザのみ 等）の全文は [`CLAUDE.md`](CLAUDE.md) の「呼称規約」を参照。

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

通信モードは `--comm-mode` で切り替える: `teams`（共有メッセージング）/ `sendkeys`（Gen1）/ `ntfy`（Gen2）/ `mailbox`・`hybrid`（Gen3）。代表例:

```bash
bin/shogun-comm --mode teams send --from shogun --to karo --content "new task"
bin/shogun-comm --mode teams read --name karo --unread-only --mark-read
```

各モードの送受信コマンドと使い分けは [`CLAUDE.md`](CLAUDE.md) の通信プロトコル表を参照。

## Agent Teams-style API

`bin/shogun-api call <Op> ...` で Agent Teams 互換の `TeamCreate` / `SendMessage` / `TaskCreate` / `TaskUpdate` / `TaskList` / `Task` を呼べる。代表例:

```bash
bin/shogun-api call TaskCreate actor=shogun owner=karo subject="WBS更新" description="分解して割り当て"
```

全 Op と引数は [`CLAUDE.md`](CLAUDE.md) の「互換API」を参照。

## Ops

代表的な運用コマンド:

```bash
bin/shogunctl status                                   # メンバー/タスク集計 + 最近のイベント
bin/shogun-remote ask "本家との差分を比較し、改善案を3案示せ"   # 思考系を将軍経由で委任
bin/shogun-remote run "pnpm test"                      # 実行系（strict delegate, 既定）
bin/shogunctl reset                                    # ランタイムデータの初期化
```

その他の運用コマンド（`shogun-feed` / `shogun-skillflow` / `shogun-watchdog` / `shogun-autoflow` / `shogun-agent` 等）と、各コマンドの全フラグ・既定値・ingress policy・root task guard は [`CLAUDE.md`](CLAUDE.md) の「CLIオプション (正本)」を参照。実行時 `--help` でも一覧できる。

## Policy

`shogun` は delegate-only（自己実行不可・足軽直指示不可・必ず `karo` 経由）。役割制約の全文は [`CLAUDE.md`](CLAUDE.md) の「役割制約」を参照。

## Project Layout

- `bin/`: control plane, comm layer, launchers, compatibility wrappers
- `instructions/`: role definitions
- `state/`: runtime state (DB/mailboxes/spool; mostly ignored from git)
- `CLAUDE.md`: protocol and role constraints
