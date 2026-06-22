# 通信プロトコル: Shogun Multi-Agent

エージェント間通信は `bin/shogun-comm` を介して行う。
モードは `SHOGUN_COMM_MODE` または `--mode` で切り替える。

| 操作 | コマンド |
|------|----------|
| メッセージ送信 | `bin/shogun-comm --mode <mode> send --from A --to B --content "..."` |
| 全体通知 | `bin/shogun-comm --mode <mode> send --from A --broadcast --content "..."` |
| タスク作成 | `bin/shogunctl task create --actor A --subject ... --description ...` |
| タスク割当 | `bin/shogunctl task update --id N --actor A --owner B` |
| タスク完了 | `bin/shogunctl task update --id N --actor A --status done` |
| 受信箱確認 | `bin/shogun-comm --mode <mode> read --name A --unread-only --mark-read` |
| 技能提案走査 | `bin/shogun-skillflow scan --once --json` |
| 技能提案一覧 | `bin/shogun-skillflow list` |
| 技能提案裁可 | `bin/shogun-skillflow approve --id N` |
| 将軍経由で思考委任 | `bin/shogun-remote ask "..."`（比較/設計/検討を task+message 化） |
| 将軍経由で実行委任 | `bin/shogun-remote run "..."`（strict default: task+message作成） |
| 直実行（例外） | `bin/shogun-remote run --direct "..."` |
| 自動家老ループ | `bin/shogun-agent --name karo --role karo --mode <mode>` |
| 自動目付ループ | `bin/shogun-agent --name metsuke --role metsuke --mode <mode>` |
| 自動足軽ループ | `bin/shogun-agent --name ashigaruN --role ashigaru --mode <mode>` |

## 互換API (Agent Teams風)

`bin/shogun-api call` で以下を使用可能:

- `TeamCreate`
- `SendMessage`
- `TaskCreate`
- `TaskUpdate`
- `TaskList`
- `Task` (subagent spawn互換)

## CLIオプション (正本)

各コマンドの全フラグは実行時 `--help` でも確認できる。以下はそのうち恒久仕様として固定するもの。

### `bin/shogun-launch`

既定値: `ashigaru=7` / `autopilot=ON` / `leader-watch=ON` / `feed=ON`（`feed-truncate=0`=全文）/ `drama=ON` / `karo-decompose-mode=auto` / `ashigaru-exec-mode=auto` / `dialogue-mode=auto` / `samurai-tone=strong` / `ashigaru-ack-wait-sec=8` / `ashigaru-progress-interval-sec=10` / `skills=ON`（`skill-interval-sec=30` / `skill-min-count=3`）。起動時に直前の task/message/event をクリアする。

| オプション | 意味 |
|------|------|
| `--no-autopilot` | 自動稼働を無効化（手動操作のみ） |
| `--agent-interval SEC` | 自動稼働ループの周期 |
| `--drama / --no-drama` | 戦国演出モードON/OFF（既定ON） |
| `--karo-decompose-mode auto\|llm\|rule` | 家老の分解モード |
| `--ashigaru-exec-mode auto\|codex\|shell` | 足軽の実行モード |
| `--dialogue-mode auto\|llm\|template` | 送信文スタイル |
| `--samurai-tone strong\|light` | 侍口調の強さ |
| `--ashigaru-ack-wait-sec SEC` | 足軽が家老の応答を待ってから実働へ移る待機時間 |
| `--ashigaru-progress-interval-sec SEC` | 足軽の中間報告間隔 |
| `--skills / --no-skills` | 自動Skill提案デーモンON/OFF（既定ON） |
| `--skill-interval-sec SEC` | Skill提案スキャン間隔 |
| `--skill-min-count N` | Skill提案の最小反復回数 |
| `--skill-sender NAME` | Skill提案メッセージ送信者名（既定 `skillsmith`） |
| `--leader-watch / --no-leader-watch` | 将軍paneの受信早馬表示ON/OFF |
| `--feed / --no-feed` | 将軍ウィンドウの全隊フィード表示ON/OFF |
| `--feed-tail-events N --feed-tail-messages N --feed-interval SEC` | フィード表示調整（`N=0` は全件） |
| `--feed-truncate N` | フィード文字数制限（`0` は要約なし全文） |
| `--watch` | 旧watchログを `/tmp/shogun-watch-*.log` へ保存 |

### `bin/shogun-agent`

| オプション | 意味 |
|------|------|
| `--output-max-chars N` | 実行ログをメッセージに含める最大文字数（`0` は無制限） |
| `--drama / --no-drama` | 役回り・檄・軍律メッセージの演出ON/OFF（`SHOGUN_DRAMA_MODE` でも指定可） |
| `--karo-decompose-mode auto\|llm\|rule` | 家老の分解戦略（既定 `auto`） |
| `--ashigaru-exec-mode auto\|codex\|shell` | 足軽の実行戦略（既定 `auto`） |
| `--dialogue-mode auto\|llm\|template` | エージェント間メッセージの自然言語化戦略（既定 `auto`） |
| `--samurai-tone strong\|light` | 自然言語メッセージの戦国口調レベル（既定 `strong`） |
| `--ashigaru-ack-wait-sec SEC` | 裁可待ちタイムアウト（既定 `8` 秒） |
| `--ashigaru-progress-interval-sec SEC` | 中間報告間隔（既定 `10` 秒） |
| `--karo-codex-bin`, `--ashigaru-codex-bin` | 自律実行に使うCodex実行ファイル（既定 `codex`） |
| `--dialogue-codex-bin` | 対話文リライトに使うCodex実行ファイル（既定 `codex`） |

### `bin/shogun-skillflow scan`（主要）

| オプション | 意味 |
|------|------|
| `--min-count N` | 提案対象にする最小反復回数 |
| `--gate-min-score S` | 価値ゲート合格点（既定 `4.5`） |
| `--research-docs / --no-research-docs` | 公式情報URL取得ON/OFF |
| `--research-llm / --no-research-llm` | LLM評価ON/OFF |
| `--require-llm-propose` | LLM推奨が `propose` のときのみ提案作成 |
| `--publish-dir PATH` | 既存Skill重複判定に使うSkill保存先 |

### `bin/shogun-remote` ingress policy

- 思考系依頼（比較・設計・検討・企画）: `bin/shogun-remote ask "..."`
- 実行系依頼（コマンド遂行）: `bin/shogun-remote run "..."`
- `run` は既定で strict（`SHOGUN_REMOTE_STRICT=1`）: task を作り `karo` へ委任メッセージを送り、`--direct` 指定時を除き直接実行しない。既定で task 完了を待ち、将軍報告を上様へ表示する。
- 完了追跡オプション: `--await / --no-await`（既定有効）/ `--await-timeout-sec N` / `--await-poll-sec SEC` / `--stream all\|task\|shogun\|off`（既定 `all`）/ `--db PATH`（既定 `state/shogun.db`）。

### Root task ingress guard

- `parent_id` のない新規タスク（root task）は `actor=shogun` のみ作成可能。
- 検証時のみ `SHOGUN_ALLOW_NON_SHOGUN_ROOT_TASKS=1` で一時緩和。
- `bin/shogun-remote` の `sender` 既定は `SHOGUN_NAME`（未設定時は `shogun`）。

## 役割制約

## 呼称規約

- `上様`: 人間ユーザのみ（将軍ではない）
- `将軍殿`: `shogun`
- `家老殿`: `karo`
- `目付殿`: `metsuke`
- `足軽N`: `ashigaruN`
- 指揮系統は `ユーザ(上様) -> 将軍 -> 家老 -> 足軽/目付`

- `shogun`: delegate-only
  - ファイル編集・実装作業を直接行わない
  - `ashigaru*` へ直指示しない
  - 必ず `karo` 経由で実行委任する
- 依頼入口（root task）は `shogun` 固定
  - `parent_id` なしの `task create` は `actor=shogun` のみ許可
- `karo`: 分解・割当・進捗管理
  - 既定は `karo-decompose-mode=auto`（Codex自律分解を優先、失敗時は規則分解へ退避）
- `metsuke`: レビュー品質ゲート
- `ashigaru*`: 実行担当
  - 既定は `ashigaru-exec-mode=auto`（Codex自律実行を優先、必要時にshell実行へ退避）
  - 会話フロー既定: 着手上申 -> 家老裁可 -> 実働 -> 完了上申
- 全役職の送信文:
  - 既定は `dialogue-mode=auto`（自然言語リライトを優先、失敗時は規則変換へ退避）
  - 既定は `samurai-tone=strong`（自然文を戦国調へ強く補正）
- 自動Skill蓄積:
  - `bin/shogun-skillflow` が完了タスクを走査し、反復作業を Skill 提案として起票
  - 既存Skill/既存提案との重複判定を行う
  - 価値ゲート（反復件数・一貫性・多様性）を満たす候補のみ提案化
  - 公式情報URL + LLM判定（推奨/保留/却下）を提案メタへ保存
  - 提案は将軍へ通知され、`approve/reject` で裁可可能
  - 裁可済みSkillは `skills/<slug>/SKILL.md` として出力され、移植可能

## 監視表示

- `bin/shogunctl status` はメンバー/タスク集計に加えて最近の `task_events` と `messages` を表示。
- `bin/shogun-launch` 既定では将軍paneで早馬ストリームを表示し、multiagent paneで各役職が将軍調ログを出力する。
- `bin/shogun-launch` 既定では `shogun:0.1` に `bin/shogun-feed` を起動し、全隊のイベント/メッセージを全件表示 + 常時追尾する。
