#!/usr/bin/env bash
set -euo pipefail

command -v firefox >/dev/null 2>&1 || {
  echo "error: firefox not found on PATH" >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date +%s)"
PROFILE="/tmp/ro-profile-${TS}"

mkdir -p "${PROFILE}/chrome"

{
  echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
  echo 'user_pref("browser.nova.enabled", true);'
  if [ "${DARK:-0}" = "1" ]; then
    echo 'user_pref("ui.systemUsesDarkTheme", 1);'
  fi
} > "${PROFILE}/user.js"

if [ -f "${ROOT}/userChrome.css" ]; then
  ln -s "${ROOT}/userChrome.css" "${PROFILE}/chrome/userChrome.css"
fi

echo "profile: ${PROFILE}" >&2
export MOZ_ENABLE_WAYLAND=0
exec firefox -no-remote -profile "${PROFILE}"
