#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${SHOGUN_COMM_MODE:-teams}"

exec "$ROOT_DIR/bin/shogun-watchdog" --mode "$MODE" "$@"

