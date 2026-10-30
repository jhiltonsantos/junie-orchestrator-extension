#!/usr/bin/env bash
# Checks that every subagent of the orchestrator extension has a usable model profile.
# Usage: doctor.sh [agents_dir] [models_dir]
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents_dir="${1:-$here/../../../agents}"
models_dir="${2:-${JUNIE_HOME:-$HOME/.junie}/models}"

fail=0
checked=0

# Linux only, best effort: does a running Junie process have this variable?
# Prints nothing when it cannot tell (no /proc, no Junie running, not readable).
junie_env_has() {
  local var="$1" pid seen=0
  [ -d /proc/self ] || return 0
  for pid in $(pgrep -x junie 2>/dev/null); do
    [ -r "/proc/$pid/environ" ] || continue
    seen=1
    if tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -q "^${var}="; then
      return 0
    fi
  done
  if [ "$seen" -eq 1 ]; then
    echo "WARN  a running Junie process does not have $var. Restart Junie from a shell where it is exported."
  fi
  return 0
}

if [ ! -d "$agents_dir" ]; then
  echo "ERROR: agents directory not found: $agents_dir"
  exit 2
fi

valid_json() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$1" >/dev/null 2>&1
  elif command -v jq >/dev/null 2>&1; then
    jq empty "$1" >/dev/null 2>&1
  else
    return 0 # no JSON tool available; skip the syntax check
  fi
}

for agent in "$agents_dir"/*.md; do
  [ -e "$agent" ] || continue
  name="$(basename "$agent" .md)"
  model="$(sed -n 's/^model:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "$agent" | head -n 1)"

  case "$model" in
    custom:*) profile="${model#custom:}" ;;
    "") echo "SKIP  $name: no model set (runs on the main agent's model)"; continue ;;
    *) echo "SKIP  $name: model '$model' is not a custom profile"; continue ;;
  esac

  checked=$((checked + 1))
  file="$models_dir/$profile.json"

  if [ ! -f "$file" ]; then
    echo "FAIL  $name: profile '$profile' not found at $file"
    echo "      Junie will silently run this subagent on the main agent's model."
    echo "      Fix: run the orchestrator-setup skill."
    fail=1
    continue
  fi

  if ! valid_json "$file"; then
    echo "FAIL  $name: $file is not valid JSON"
    fail=1
    continue
  fi

  vars="$(sed -n 's/.*"apiKey"[[:space:]]*:[[:space:]]*"\${\([A-Za-z_][A-Za-z0-9_]*\)}".*/\1/p' "$file")"
  if [ -z "$vars" ]; then
    if grep -q '"apiKey"' "$file"; then
      echo "WARN  $name: apiKey in $file is a literal value; prefer a \${VAR} reference and keep keys out of files"
    else
      echo "WARN  $name: no apiKey in $file (requests are sent without authentication)"
    fi
  else
    for v in $vars; do
      if [ -z "${!v:-}" ]; then
        echo "FAIL  $name: environment variable $v is not set in this shell"
        echo "      Export it in the shell that starts Junie and restart Junie, or the profile will fail to load."
        fail=1
        continue 2
      fi
    done
  fi

  for v in $vars; do junie_env_has "$v"; done
  echo "OK    $name: profile '$profile' found"
done

if [ "$checked" -eq 0 ]; then
  echo "No custom-profile subagents found in $agents_dir"
  exit 2
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "Doctor found problems."
  exit 1
fi
echo
echo "All checked profiles look good."
