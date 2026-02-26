#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${SHOGUN_COMM_MODE:-hybrid}"

usage() {
  cat <<'EOF'
Usage: bin/inbox_read.sh --name AGENT [--limit N] [--mark-read] [--json] [--since-id N]
EOF
}

NAME=""
LIMIT="100"
MARK_READ=0
JSON_OUT=0
SINCE_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --mark-read) MARK_READ=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --since-id) SINCE_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$NAME" ]]; then
  usage
  exit 1
fi

CMD=("$ROOT_DIR/bin/shogun-comm" "--mode" "$MODE" "read" "--name" "$NAME" "--limit" "$LIMIT")
if [[ "$MARK_READ" -eq 1 ]]; then
  CMD+=("--mark-read")
fi
if [[ "$JSON_OUT" -eq 1 ]]; then
  CMD+=("--json")
fi
if [[ -n "$SINCE_ID" ]]; then
  CMD+=("--since-id" "$SINCE_ID")
fi

"${CMD[@]}"

