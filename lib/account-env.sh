#!/usr/bin/env zsh
set -euo pipefail

agentic_usage() {
  print -u2 "usage: $0 <personal|corp> [command...]"
}

agentic_resolve_account() {
  local account="${1:-}"
  case "$account" in
    personal|corp) print -- "$account" ;;
    *) agentic_usage; return 64 ;;
  esac
}

agentic_export_env() {
  local account
  account="$(agentic_resolve_account "${1:-}")"

  export AGENTIC_ACCOUNT="$account"
  export AGENTIC_ACCOUNTS_ROOT="${AGENTIC_ACCOUNTS_ROOT:-$HOME/AgenticAccounts}"
  export AGENTIC_ACCOUNT_ROOT="$AGENTIC_ACCOUNTS_ROOT/$account"
  export AGENTIC_SHARED_ROOT="$AGENTIC_ACCOUNTS_ROOT/shared"

  local inheritance_file="$AGENTIC_ACCOUNT_ROOT/env/inheritance.env"
  if [[ -f "$inheritance_file" ]]; then
    source "$inheritance_file"
  fi

  export CODEX_HOME="$AGENTIC_ACCOUNT_ROOT/codex"
  export CLAUDE_CONFIG_DIR="$AGENTIC_ACCOUNT_ROOT/claude"
  export OPENCODE_CONFIG_DIR="$AGENTIC_ACCOUNT_ROOT/opencode"

  export XDG_CONFIG_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/config"
  export XDG_CACHE_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/cache"
  export XDG_DATA_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/data"
  export XDG_STATE_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/state"

  if [[ -n "${AGENTIC_GH_CONFIG_DIR:-}" ]]; then
    export GH_CONFIG_DIR="$AGENTIC_GH_CONFIG_DIR"
    export AGENTIC_GH_AUTH_MODE="custom"
  elif [[ "${AGENTIC_INHERIT_GH:-0}" == "1" ]]; then
    export GH_CONFIG_DIR="$HOME/.config/gh"
    export AGENTIC_GH_AUTH_MODE="inherited-global"
  else
    export GH_CONFIG_DIR="$CODEX_HOME/github"
    export AGENTIC_GH_AUTH_MODE="isolated"
  fi

  export GIT_CONFIG_GLOBAL="$AGENTIC_ACCOUNT_ROOT/git/config"
  export TMPDIR="$AGENTIC_ACCOUNT_ROOT/tmp"

  export CLAUDE_CODE_TMPDIR="$AGENTIC_ACCOUNT_ROOT/tmp"
  export CLAUDE_CODE_SUBPROCESS_ENV_SCRUB="${CLAUDE_CODE_SUBPROCESS_ENV_SCRUB:-1}"

  unset OPENAI_API_KEY
  unset ANTHROPIC_API_KEY
  unset ANTHROPIC_AUTH_TOKEN
  unset GH_TOKEN
  unset GITHUB_TOKEN
  unset VERCEL_TOKEN
  unset VERCEL_ORG_ID
  unset VERCEL_PROJECT_ID
  unset TURBO_TOKEN
  unset HOSTINGER_API_TOKEN
  unset HOSTINGER_TOKEN
  unset GOOGLE_APPLICATION_CREDENTIALS
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  local env_file="$AGENTIC_ACCOUNT_ROOT/env/account.env"
  if [[ -f "$env_file" ]]; then
    set -a
    source "$env_file"
    set +a
  fi

  mkdir -p "$TMPDIR"
}
