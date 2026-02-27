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
