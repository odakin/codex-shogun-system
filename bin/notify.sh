#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${SHOGUN_COMM_MODE:-hybrid}"

usage() {
  cat <<'EOF'
Usage: bin/notify.sh --from SENDER (--to RECIPIENT | --broadcast) --content TEXT [--summary TEXT] [--task-id N]
EOF
}

FROM=""
TO=""
CONTENT=""
SUMMARY=""
TASK_ID=""
BROADCAST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --to) TO="$2"; shift 2 ;;
    --broadcast) BROADCAST=1; shift ;;
    --content) CONTENT="$2"; shift 2 ;;
    --summary) SUMMARY="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$FROM" || -z "$CONTENT" ]]; then
  usage
  exit 1
fi

CMD=("$ROOT_DIR/bin/shogun-comm" "--mode" "$MODE" "send" "--from" "$FROM" "--content" "$CONTENT")
if [[ "$BROADCAST" -eq 1 ]]; then
  CMD+=("--broadcast")
else
  if [[ -z "$TO" ]]; then
    echo "error: --to is required unless --broadcast" >&2
    exit 1
  fi
  CMD+=("--to" "$TO")
fi
if [[ -n "$SUMMARY" ]]; then
  CMD+=("--summary" "$SUMMARY")
fi
if [[ -n "$TASK_ID" ]]; then
  CMD+=("--task-id" "$TASK_ID")
fi

"${CMD[@]}"

