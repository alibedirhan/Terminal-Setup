#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

stamp="$(date +%Y%m%d_%H%M%S)"
out_dir="$ROOT_DIR/logs/terminal_setup_logs_$stamp"
mkdir -p "$out_dir"

{
  echo "Terminal Setup Log Pack"
  echo "Date: $(date --iso-8601=seconds)"
  echo "Root: $ROOT_DIR"
  echo "VERSION: $(cat VERSION 2>/dev/null || true)"
  echo
  uname -a || true
  echo
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a || true
  fi
  echo
  echo "SHELL=${SHELL:-unknown}"
  echo "TERM=${TERM:-unknown}"
  echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unknown}"
} > "$out_dir/environment.txt" 2>&1

bash scripts/check_static.sh > "$out_dir/check_static.txt" 2>&1 || true

if [[ -f "$HOME/.terminal-setup/logs/terminal-setup.log" ]]; then
  cp "$HOME/.terminal-setup/logs/terminal-setup.log" "$out_dir/terminal-setup.log"
fi

{
  command -v zsh && zsh --version || true
  command -v git && git --version || true
  command -v curl && curl --version | head -1 || true
  command -v wget && wget --version | head -1 || true
  command -v fzf && fzf --version || true
  command -v zoxide && zoxide --version || true
  command -v eza && eza --version | head -1 || true
  command -v batcat && batcat --version || true
} > "$out_dir/tools.txt" 2>&1

cd "$ROOT_DIR/logs"
zip -r "terminal_setup_logs_$stamp.zip" "terminal_setup_logs_$stamp" >/dev/null

echo "Log paketi hazır: $ROOT_DIR/logs/terminal_setup_logs_$stamp.zip"
