#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN="${SHOGUN_NUDGE_TOKEN:-nudge}"

usage() {
  cat <<'EOF'
Usage: bin/nudge_send.sh --from SENDER (--to RECIPIENT | --broadcast) [--token TOKEN]
EOF
}

FROM=""
TO=""
BROADCAST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --to) TO="$2"; shift 2 ;;
    --broadcast) BROADCAST=1; shift ;;
    --token) TOKEN="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$FROM" ]]; then
  usage
  exit 1
fi

CMD=("$ROOT_DIR/bin/shogun-comm" "nudge" "--from" "$FROM" "--token" "$TOKEN")
if [[ "$BROADCAST" -eq 1 ]]; then
  CMD+=("--broadcast")
else
  if [[ -z "$TO" ]]; then
    echo "error: --to is required unless --broadcast" >&2
    exit 1
  fi
  CMD+=("--to" "$TO")
fi

"${CMD[@]}"

