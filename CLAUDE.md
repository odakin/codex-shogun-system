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
| 将軍経由で委任 | `bin/shogun-remote run "..."`（strict default: task+message作成） |
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

- `shogun`: delegate-only
  - ファイル編集・実装作業を直接行わない
  - `ashigaru*` へ直指示しない
  - 必ず `karo` 経由で実行委任する
- `karo`: 分解・割当・進捗管理
- `metsuke`: レビュー品質ゲート
- `ashigaru*`: 実行担当

## 監視表示

- `bin/shogunctl status` はメンバー/タスク集計に加えて最近の `task_events` と `messages` を表示。
- `bin/shogun-launch` 既定では将軍paneで早馬ストリームを表示し、multiagent paneで各役職が将軍調ログを出力する。
