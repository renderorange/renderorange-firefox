#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $(basename "$0") <label>" >&2
  exit 1
fi
LABEL="$1"

for tool in xwininfo import; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "error: ${tool} not found on PATH" >&2
    exit 1
  }
done

[ -n "${DISPLAY:-}" ] || {
  echo "error: DISPLAY not set" >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${ROOT}/shots"

IDS="$(xwininfo -root -tree | grep -i 'mozilla firefox' | awk '{print $1}')"

if [ -z "${IDS}" ]; then
  echo "error: no Firefox windows found" >&2
  exit 1
fi

for id in ${IDS}; do
  import -window "$id" "${ROOT}/shots/${LABEL}.png"
  echo "${ROOT}/shots/${LABEL}.png"
done
