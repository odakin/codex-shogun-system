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

